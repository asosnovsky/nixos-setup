
# robotnix: manage robotnix robots (self-managed NixOS nspawn containers).
# CONFIG and PATH are set by the Nix wrapper (robots.nix) above this line.

def cfg [] { open $CONFIG }

def robot [name: string] {
  let robots = (cfg).robots
  if $name not-in ($robots | columns) {
    error make { msg: $"unknown robot '($name)'. Known: ($robots | columns | str join ', ')" }
  }
  $robots | get $name
}

def need-root [] {
  if not (is-admin) { error make { msg: "this needs root: run it with sudo" } }
}

def units [r: record] {
  {
    robot: $"($r.unit).service"
    storage: $"($r.unit)-storage.service"
    seed: $"($r.unit)-seed.service"
    dns: $"($r.unit)-dns.service"
  }
}

def unit-state [unit: string] {
  ^systemctl is-active $unit | complete | get stdout | str trim
}

def is-mounted [dir: string] {
  (^mountpoint -q $dir | complete).exit_code == 0
}

def disk-usage [dir: string] {
  if not (is-mounted $dir) { return "-" }
  let f = (^df -B1 --output=used,size $dir | lines | last | str trim | split row -r '\s+')
  $"($f.0 | into filesize) / ($f.1 | into filesize)"
}

def stamp [] { date now | format date "%Y-%m-%dT%H-%M-%S" }

def confirm-name [name: string, what: string] {
  print $what
  let answer = (input $"Type '($name)' to continue: ")
  if $answer != $name { error make { msg: "aborted" } }
}

# Stop the robot and unmount its images (seed and robot are bound to storage).
def stop-robot [r: record] {
  let u = (units $r)
  ^systemctl stop $u.robot $u.seed $u.storage
}

# What a snapshot covers. Ephemeral robots reset root on every start, so
# only home is worth keeping.
def parts [r: record] {
  if $r.ephemeral { [home] } else { [root home] }
}

# Snapshot ids are "<stamp>-<kind>", e.g. 2026-10-23T14-00-00-auto.
def snapshot-list [r: record] {
  let dir = $"($r.base)/snapshots"
  if not ($dir | path exists) { return [] }
  ls $dir
  | where type == dir
  | each {|e| $e.name | path basename }
  | sort
  | each {|id|
      let p = ($id | parse -r '^(?<stamp>\d{4}-\d{2}-\d{2}T\d{2}-\d{2}-\d{2})-(?<kind>.+)$')
      if ($p | is-empty) {
        { id: $id, kind: "?", created: "?" }
      } else {
        { id: $id, kind: $p.0.kind, created: ($p.0.stamp | str replace 'T' ' ') }
      }
    }
}

# Freeze the filesystems (if mounted), snapshot the subvolumes, thaw.
def take-snapshot [r: record, kind: string] {
  let id = $"(stamp)-($kind)"
  let dest = $"($r.base)/snapshots/($id)"
  mkdir $dest
  let mounts = (parts $r | each {|p| $"($r.run)/($p)" } | where {|m| is-mounted $m })
  let err = (try {
    for m in $mounts { ^fsfreeze -f $m }
    for sub in (parts $r) {
      ^btrfs subvolume snapshot -r $"($r.base)/($sub)" $"($dest)/($sub)"
    }
    null
  } catch {|e| $e.msg })
  for m in $mounts { do -i { ^fsfreeze -u $m } }
  if $err != null { error make { msg: $"snapshot of ($r.name) failed: ($err)" } }
  $id
}

def delete-snapshot [r: record, id: string] {
  let d = $"($r.base)/snapshots/($id)"
  if not ($d | path exists) { error make { msg: $"no snapshot '($id)' for ($r.name)" } }
  for sub in [root home] {
    if ($"($d)/($sub)" | path exists) { ^btrfs subvolume delete $"($d)/($sub)" }
  }
  ^rmdir $d
}

# Keep only the newest `keep` automatic snapshots. Others are never pruned.
def prune [r: record] {
  let autos = (snapshot-list $r | where kind == "auto" | each {|s| $s.id })
  let extra = ($autos | length) - $r.snapshots.keep
  if $extra > 0 {
    for id in ($autos | first $extra) { delete-snapshot $r $id }
  }
}

# Manage robotnix robots. Run `robotnix <command> --help` for details.
def main [] {
  print "robotnix - self-managed NixOS nspawn robots

  list                          all robots: state, IP, disk use
  status <robot>                unit status
  start|stop|restart <robot>
  shell <robot> [--root]        log in without ssh (machinectl)
  snapshot <robot> [--tag t]    take a snapshot now
  snapshots <robot>             list snapshots
  forget <robot> <id>           delete a snapshot
  restore <robot> <id> [--only root|home]
  reseed <robot> [--wipe-home]  reinstall from the seed config
  access <robot>                effective network rules"
}

# All robots with state, address and disk use.
def "main list" [] {
  (cfg).robots | transpose name r | each {|row|
    let r = $row.r
    {
      name: $row.name
      state: (unit-state $"($r.unit).service")
      address: $r.address
      internet: $r.access.internet
      root: (disk-usage $"($r.run)/root")
      home: (disk-usage $"($r.run)/home")
      snapshots: (snapshot-list $r | length)
      ephemeral: $r.ephemeral
    }
  }
}

# systemd status of a robot and its helper units.
def "main status" [name: string] {
  let u = (units (robot $name))
  do -i { ^systemctl status --no-pager --lines=10 $u.robot $u.dns $u.storage }
}

def "main start" [name: string] {
  need-root
  ^systemctl start (units (robot $name)).robot
}

def "main stop" [name: string] {
  need-root
  ^systemctl stop (units (robot $name)).robot
}

def "main restart" [name: string] {
  need-root
  ^systemctl restart (units (robot $name)).robot
}

# Log into a robot without ssh. Works even if its network is broken.
def "main shell" [name: string, --root] {
  let r = (robot $name)
  let who = if $root { "root" } else { $r.user }
  ^machinectl shell $"($who)@($r.name)"
}

# Take a consistent snapshot of the robot's root and home.
def "main snapshot" [
  name: string
  --tag: string = "manual"  # label for the snapshot id
  --auto                    # timer mode: tag "auto" and prune old ones
] {
  need-root
  let r = (robot $name)
  let kind = if $auto { "auto" } else { $tag }
  if not ($kind =~ '^[a-z0-9-]+$') { error make { msg: "--tag may only use a-z, 0-9 and -" } }
  let id = (take-snapshot $r $kind)
  if $auto { prune $r }
  print $"snapshot ($id) taken for ($name)"
}

# List a robot's snapshots.
def "main snapshots" [name: string] {
  snapshot-list (robot $name)
}

# Delete one snapshot.
def "main forget" [name: string, id: string] {
  need-root
  delete-snapshot (robot $name) $id
  print $"deleted snapshot ($id) of ($name)"
}

# Roll a robot back to a snapshot. The current state is saved first.
def "main restore" [
  name: string
  id: string
  --only: string  # "root" or "home" (default: both)
  --yes           # skip the confirmation
] {
  need-root
  let r = (robot $name)
  let subs = if $only == null {
    parts $r
  } else if $only in (parts $r) {
    [$only]
  } else {
    error make { msg: $"--only must be one of: (parts $r | str join ', ')" }
  }
  let src = $"($r.base)/snapshots/($id)"
  for sub in $subs {
    if not ($"($src)/($sub)" | path exists) { error make { msg: $"snapshot ($id) has no ($sub)" } }
  }
  if not $yes {
    confirm-name $name $"This replaces ($name)'s ($subs | str join ' and ') with snapshot ($id).\nThe current state is kept as a pre-restore snapshot."
  }
  stop-robot $r
  let saved = (take-snapshot $r "pre-restore")
  for sub in $subs {
    ^btrfs subvolume delete $"($r.base)/($sub)"
    ^btrfs subvolume snapshot $"($src)/($sub)" $"($r.base)/($sub)"
  }
  ^systemctl start (units $r).robot
  print $"($name) restored to ($id). Undo with: robotnix restore ($name) ($saved)"
}

# Wipe a robot's OS and reinstall it from its seed config.
def "main reseed" [
  name: string
  --wipe-home  # also start with an empty /home
  --yes        # skip the confirmation
] {
  need-root
  let r = (robot $name)
  let what = if $wipe_home { "root AND home" } else { "root (home is kept)" }
  if not $yes {
    confirm-name $name $"This wipes ($name)'s ($what) and reinstalls it from its seed config.\nA pre-reseed snapshot is taken first."
  }
  stop-robot $r
  let saved = (take-snapshot $r "pre-reseed")
  rm -f $"($r.base)/root/root.img"
  # Ephemeral: drop the clean root too, so the next start reinstalls.
  if $r.ephemeral {
    rm -f $"($r.base)/pristine.id"
    if ($"($r.base)/pristine" | path exists) { ^btrfs subvolume delete $"($r.base)/pristine" }
  }
  if $wipe_home { rm -f $"($r.base)/home/home.img" }
  ^systemctl start (units $r).robot
  print $"($name) reseeded. Undo with: robotnix restore ($name) ($saved)"
}

# Show a robot's effective (shared + own) network rules.
def "main access" [name: string] {
  let r = (robot $name)
  print ($r.access | table --expand)
  if $r.access.internet == "allowlist" {
    print "IPs learned from allowed domains:"
    do -i { ^nft list set inet robotnix $"allow_($r.nft)" }
  }
}
