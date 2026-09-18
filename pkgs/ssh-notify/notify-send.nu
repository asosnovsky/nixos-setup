#!/usr/bin/env nu
# Drop-in `notify-send` replacement.
#
# - Local session (no $SSH_CONNECTION): passes through to the real libnotify
#   `notify-send` unchanged.
# - SSH session with a live per-connection forward ($SSH_NOTIFY_SOCK set by
#   the client's `SetEnv`, and the socket file present): encodes the message
#   as JSON and hands it to `socat` to relay over the forwarded Unix socket
#   to the listener on the client desktop.
# - SSH session with no forward available (client didn't request one, or the
#   remote bind failed): no-op. There is no notification daemon to call on a
#   headless host, so falling through to the real binary would just reproduce
#   the `ServiceUnknown` D-Bus error this wrapper exists to avoid.
#
# @real_notify_send@ is substituted at build time with the libnotify binary's
# store path.

def main [title: string, body: string = "", ...rest: string]: nothing -> nothing {
    let ssh_connection = ($env.SSH_CONNECTION? | default "")
    let notify_sock = ($env.SSH_NOTIFY_SOCK? | default "")

    if ($ssh_connection | is-empty) {
        ^@real_notify_send@ $title $body ...$rest
        return
    }

    if ($notify_sock | is-empty) or (not ($notify_sock | path exists)) {
        return
    }

    let host = (^hostname -s | str trim)
    let payload = { host: $host, title: $title, body: $body } | to json --raw

    try {
        $payload | ^socat - $"UNIX-CONNECT:($notify_sock)"
    } catch {
        # Best-effort: a race where the forward closed between the exists
        # check and the connect attempt isn't worth surfacing to the caller.
    }
}
