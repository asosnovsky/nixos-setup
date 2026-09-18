#!/usr/bin/env nu
# Client-side (desktop) listener. Runs one persistent `socat` listen socket
# at a fixed, per-user path. This can stay fixed (unlike the per-connection
# *remote*-side socket) because `fork` mode lets it accept an unbounded
# number of connections over its lifetime -- one per `notify-send` call from
# any concurrently forwarded SSH session.
#
# Each accepted connection is handed off to `ssh-notify-handle-connection`,
# which reads one JSON payload and turns it into a real desktop notification.
#
# @handle_connection@ is substituted at build time with that script's store
# path.

def main [] {
    let uid = (^id -u | str trim)
    let dir = $"/run/user/($uid)/ssh-notify"
    mkdir $dir
    let sock = $"($dir)/listener.sock"

    # /run/user/<uid> is tmpfs and owned solely by this user, so unlike the
    # old shared /tmp path there's no cross-boot/cross-owner rm race here.
    rm -f $sock

    ^socat $"UNIX-LISTEN:($sock),fork,mode=0666" $"EXEC:@handle_connection@"
}
