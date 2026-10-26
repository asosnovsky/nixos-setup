use types.nu *
use helpers.nu *

# Same host as RELAY_URL in hosts/hl-minipc1/services/buzz.nix (public domain).
const BUZZ_DEFAULT_RELAY = "https://buzz.home.sosnovsky.ca"

# Robots that have a secrets/robots-<name>.age (robots-shared is not a robot).
def buzz-robots [] {
    secret-names
    | where {|s| ($s | str starts-with "robots-") and $s != "robots-shared" }
    | each {|s| $s | str replace "robots-" "" }
}

# Drop existing KEY=... lines for the keys in `vars` and in `drop`, then append
# the new values. Every other line is kept as is.
def env-merge [lines: list<string>, vars: record, drop: list<string>] {
    let keys = (($vars | columns) ++ $drop)
    let kept = ($lines | where {|l|
        let t = ($l | str trim)
        not ($keys | any {|k| $t | str starts-with $"($k)=" })
    })
    $kept ++ ($vars | items {|k, v| $"($k)=($v)" })
}

# Make a Buzz (Nostr) identity for a robot's Hermes agent and write the BUZZ_*
# env vars into secrets/robots-<robot>.age. Other lines in the secret are kept.
# By default the bot answers anyone on the relay (BUZZ_ALLOW_ALL_USERS=true).
# Pass --allowed-users for an explicit list, or --restricted for no one.
# The nsec is never printed. Afterwards, add the printed npub to the relay.
export def "skyg buzz identity" [
    robot: string@buzz-robots   # Robot name (secret: secrets/robots-<robot>.age)
    --relay: string             # BUZZ_RELAY_URL (default: the lab relay)
    --allowed-users: string     # Only these answer: comma-separated npubs or hex pubkeys (BUZZ_ALLOWED_USERS)
    --restricted                # Neither allow-all nor a list is set: the bot ignores everyone until you add one
    --channels: string          # BUZZ_CHANNELS: comma-separated channel UUIDs
    --home-channel: string      # BUZZ_HOME_CHANNEL: channel UUID for cron/notifications
    --rotate                    # Replace an existing BUZZ_PRIVATE_KEY (loses relay membership)
    --dry-run                   # Make a key and show the npub; do not touch the secret
] {
    cd $REPO_ROOT
    if (which nak | is-empty) {
        error make {msg: "nak not found — run inside the dev shell (nix develop)"}
    }
    let secret = $"secrets/robots-($robot).age"
    let relay_url = ($relay | default $BUZZ_DEFAULT_RELAY | str trim --right --char "/")

    # Read the current secret first, so we fail before making anything.
    mut existing = []
    if not $dry_run {
        if not ($secret | path exists) {
            error make {msg: $"($secret) not found — create it first (skyg secrets edit robots-($robot))"}
        }
        $existing = (^agenix -d $secret | lines)
        let has_key = ($existing | any {|l| ($l | str trim) | str starts-with "BUZZ_PRIVATE_KEY=" })
        if $has_key and not $rotate {
            error make {msg: $"($secret) already has BUZZ_PRIVATE_KEY. Use --rotate to replace it (the robot gets a new identity and must be re-added to the relay)."}
        }
    }

    let hex = (^nak key generate | str trim)
    let pubhex = (^nak key public $hex | str trim)
    let nsec = (^nak encode nsec $hex | str trim)
    let npub = (^nak encode npub $pubhex | str trim)
    let ok = ($nsec | str starts-with "nsec1") and ($npub | str starts-with "npub1")
    if not $ok {
        error make {msg: "nak returned an unexpected key format; nothing was written"}
    }

    mut vars = {BUZZ_RELAY_URL: $relay_url, BUZZ_PRIVATE_KEY: $nsec}
    if ($allowed_users | is-not-empty) { $vars = ($vars | insert BUZZ_ALLOWED_USERS $allowed_users) }
    if ($channels | is-not-empty) { $vars = ($vars | insert BUZZ_CHANNELS $channels) }
    if ($home_channel | is-not-empty) { $vars = ($vars | insert BUZZ_HOME_CHANNEL $home_channel) }
    # Allow-all is the default; a list or --restricted turns it off (and clears a stale true).
    mut drop = []
    if ($allowed_users | is-not-empty) {
        $vars = ($vars | insert BUZZ_ALLOWED_USERS $allowed_users)
        $drop = ["BUZZ_ALLOW_ALL_USERS"]
    } else if $restricted {
        $drop = ["BUZZ_ALLOW_ALL_USERS"]
    } else {
        $vars = ($vars | insert BUZZ_ALLOW_ALL_USERS "true")
    }

    if $dry_run {
        print $"Dry run: nothing written. Would set in ($secret):"
        print ($vars | columns | each {|k| $"  ($k)" } | str join "\n")
        if ($drop | is-not-empty) { print $"Would remove: ($drop | str join ', ')" }
        print $"npub: ($npub)"
        return
    }

    # Only --restricted can leave nobody allowed.
    let gated = (
        ($allowed_users | is-not-empty)
        or ($existing | any {|l| ($l | str trim) | str starts-with "BUZZ_ALLOWED_USERS=" })
    )

    # Straight into agenix over stdin: no plaintext file on disk.
    let body = ((env-merge $existing $vars $drop) | str join "\n") + "\n"
    $body | ^agenix -e $secret

    print $"✅ Updated ($secret) with: ($vars | columns | str join ', ')"
    print $"npub: ($npub)"
    print "Next:"
    print $"  1. On hl-minipc1: sudo buzz-manage add-member ($npub)"
    print $"  2. Rebuild, then restart the robot: robotnix restart ($robot)"
    if $restricted and not $gated {
        print "⚠️  --restricted with no BUZZ_ALLOWED_USERS: the bot will ignore everyone. Re-run with --rotate --allowed-users <npub,...> or edit the secret."
    }
}
