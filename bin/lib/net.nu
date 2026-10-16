use profile.nu *
use helpers.nu [REPO_ROOT]

const NIC_SCRIPT = path self | path dirname | path join "net-nic.sh"
const SSH_OPTS = ["-o" "BatchMode=yes" "-o" "ConnectTimeout=5" "-o" "StrictHostKeyChecking=accept-new"]
const CHECKS_DIR = $REPO_ROOT | path join ".tmp" "net-checks"
const SERVER_CACHE = $CHECKS_DIR | path join "server.nuon"

def local-hostname [] {
    ^cat /proc/sys/kernel/hostname | str trim
}

# Devices `skyg net check` can test: every remote (hl-*) profile, plus this machine if it is a profile.
export def net-targets [] {
    let local = (local-hostname)
    valid_profiles
    | each {|p|
        if ($p | str starts-with "hl-") {
            $p | str replace "hl-" ""
        } else if $p == $local {
            $p
        } else {
            null
        }
    }
    | compact
}

def is-local [device: string] {
    let local = (local-hostname)
    $device == $local or $"hl-($device)" == $local
}

# Run a bash script on a device (locally or over SSH) and return the `complete` record.
def run-on [device: string, script: string] {
    if (is-local $device) {
        $script | ^bash -s | complete
    } else {
        $script | ^ssh ...$SSH_OPTS $"root@($device).lab.internal" bash -s | complete
    }
}

def is-online [device: string] {
    if (is-local $device) { return true }
    (^ssh ...$SSH_OPTS $"root@($device).lab.internal" true | complete | get exit_code) == 0
}

def to-int-or-null [v] {
    if ($v | is-empty) { return null }
    try {
        let n = ($v | into int)
        if $n > 0 { $n } else { null }
    } catch { null }
}

def bps-to-mbps [v] {
    if $v == null { null } else { ($v * 8 / 1_000_000) | math round --precision 1 }
}

# Read the device's network card details via net-nic.sh (KEY=VALUE lines -> record).
def probe-nic [device: string] {
    let r = (run-on $device (^cat $NIC_SCRIPT))
    $r.stdout
    | lines
    | parse --regex '^(?P<key>[A-Z]+)=(?P<value>.*)$'
    | reduce --fold {} {|it, acc| $acc | upsert $it.key ($it.value | str trim) }
}

# Nearby speedtest.net servers as [{id, rest}], closest first.
def list-servers [] {
    let r = (^bash -c "nix-shell -p speedtest-go --run 'speedtest-go --list'" | complete)
    $r.stdout
    | lines
    | parse --regex '^\[(?P<id>\d+)\]\s+(?P<rest>.*)$'
}

def save-server [s: record] {
    mkdir $CHECKS_DIR
    $s | save --force $SERVER_CACHE
}

# Server id to use for all devices: the saved one (asks if you want to change it),
# or the closest one on first run. Returns "" if none could be found.
def pick-server [] {
    # ^cat, not open: open may be aliased (e.g. to xdg-open) in the user's config.
    let saved = if ($SERVER_CACHE | path exists) { try { ^cat $SERVER_CACHE | from nuon } catch { null } } else { null }

    if $saved == null {
        print "Finding the closest speedtest server (shared by all devices)..."
        let s = (list-servers | get 0?)
        if $s == null {
            print $"(ansi yellow)Could not list servers; each device will pick its own.(ansi reset)"
            return ""
        }
        save-server $s
        print $"Using server ($s.id): ($s.rest) \(saved to ($SERVER_CACHE)\)"
        return $s.id
    }

    print $"Saved server ($saved.id): ($saved.rest)"
    let ans = (input "Change server? [y/N] " | str trim | str downcase)
    if $ans not-in ["y" "yes"] { return $saved.id }

    print "Listing speedtest servers..."
    let servers = (list-servers)
    if ($servers | is-empty) {
        print $"(ansi yellow)Could not list servers; keeping saved server.(ansi reset)"
        return $saved.id
    }
    let s = ($servers | input list --fuzzy --display {|x| $"[($x.id)] ($x.rest)" } "Pick a server (closest first)")
    if $s == null {
        print "No server picked; keeping saved server."
        return $saved.id
    }
    save-server $s
    print $"Using server ($s.id): ($s.rest)"
    $s.id
}

# Run speedtest-go on a device. Assumes dl_speed/ul_speed are bytes/s and latency is ns.
def run-speedtest [device: string, server: string] {
    let srv = if $server == "" { "" } else { $"--server ($server)" }
    let r = (run-on $device $"timeout 600 nix-shell -p speedtest-go --run 'speedtest-go ($srv) --json'")
    let json_line = ($r.stdout | lines | where {|l| $l | str starts-with "{" } | reverse | get 0?)
    let s = if $json_line == null { null } else {
        try { $json_line | from json | get servers.0 } catch { null }
    }
    if $s == null {
        let err = ($r.stderr | lines | where {|l| $l != "" } | last 1 | str join)
        return {ok: false, error: (if $err == "" { $"exit code ($r.exit_code)" } else { $err })}
    }
    {
        ok: true
        server: $"($s.id? | default '?') ($s.name? | default '') / ($s.sponsor? | default '')"
        ping_ms: (if $s.latency? == null { null } else { ($s.latency / 1_000_000) | math round --precision 1 })
        down_mbps: (bps-to-mbps $s.dl_speed?)
        up_mbps: (bps-to-mbps $s.ul_speed?)
    }
}

def empty-row [device: string, status: string] {
    {
        host: $device, status: $status, iface: "", nic: "", type: "", model: "", driver: ""
        link_mbps: null, supported_mbps: "", max_mbps: null
        server: null, ping_ms: null, down_mbps: null, up_mbps: null
    }
}

# Check each managed device's network card and run a speed test against one shared server.
export def "skyg net check" [
    device?: string@net-targets, # Only check this device (default: all devices)
    --server: string = "",       # speedtest.net server id (default: closest to this machine)
    --no-speedtest,              # Only report network card details
    --save: path,                # Also save the table here (format from extension: .csv, .json, .nuon, .md, ...)
] {
    let all = (net-targets)
    let devices = if $device == null { $all } else {
        if not ($device in $all) {
            error make {msg: $"Unknown device '($device)'. Valid devices: ($all | str join ', ')"}
        }
        [$device]
    }

    let server_id = if (not $no_speedtest) and $server == "" { pick-server } else { $server }

    let total = ($devices | length)
    mut rows = []
    for it in ($devices | enumerate) {
        let d = $it.item
        let tag = $"[($it.index + 1)/($total)] ($d)"

        print $"($tag): checking reachability..."
        if not (is-online $d) {
            print $"($tag): (ansi yellow)OFFLINE(ansi reset)"
            $rows = ($rows | append (empty-row $d "offline"))
            continue
        }

        print $"($tag): reading network card..."
        let nic = (probe-nic $d)
        let supported = ($nic.SUPPORTED? | default "" | split row " " | where {|x| $x != "" })
        let max = if ($supported | is-empty) { null } else { $supported | each {|x| $x | into int } | math max }
        let model = ([($nic.VENDOR? | default "") ($nic.MODEL? | default "")] | where {|x| $x != "" } | str join " ")
        mut row = (empty-row $d "online" | merge {
            iface: ($nic.IFACE? | default "")
            nic: ($nic.NIC? | default "")
            type: ($nic.TYPE? | default "")
            model: $model
            driver: ($nic.DRIVER? | default "")
            link_mbps: (to-int-or-null ($nic.LINK? | default ""))
            supported_mbps: ($supported | str join " ")
            max_mbps: $max
        })
        print $"($tag): ($row.nic) \(($row.type)\) ($model) | link ($row.link_mbps | default '?') Mbps | supports up to ($max | default '?') Mbps"

        if not $no_speedtest {
            print $"($tag): running speedtest-go \(first run may download it via nix-shell\)..."
            let st = (run-speedtest $d $server_id)
            if $st.ok {
                $row = ($row | merge ($st | reject ok))
                print $"($tag): (ansi green)down ($st.down_mbps) Mbps, up ($st.up_mbps) Mbps, ping ($st.ping_ms) ms(ansi reset)"
            } else {
                $row = ($row | upsert status "speedtest failed")
                print $"($tag): (ansi red)speedtest failed: ($st.error)(ansi reset)"
            }
        }

        $rows = ($rows | append $row)
    }

    print $"Done: checked ($total) device\(s\)."

    mkdir $CHECKS_DIR
    let auto_file = ($CHECKS_DIR | path join $"(date now | format date '%Y.%m.%d_%H_%M_%S').nuon")
    $rows | save --force $auto_file
    print $"Saved to ($auto_file)"
    if $save != null {
        $rows | save --force $save
        print $"Saved to ($save | path expand)"
    }
    print $"Show the last table again with: (ansi green_bold)skyg net last(ansi reset)"

    $rows
}

# Show the table from the most recent `skyg net check` run.
export def "skyg net last" [] {
    # glob and ^cat, not ls/open: they may be aliased (e.g. to eza/xdg-open) in the user's config.
    let files = (glob ($CHECKS_DIR | path join "*.nuon") | where {|f| $f != $SERVER_CACHE })
    if ($files | is-empty) {
        error make {msg: $"No saved net checks in ($CHECKS_DIR). Run `skyg net check` first."}
    }
    let latest = ($files | sort | last)
    print $"From ($latest)"
    ^cat $latest | from nuon
}
