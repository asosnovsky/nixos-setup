#!/usr/bin/env nu
# Invoked by `socat EXEC:` once per accepted connection on the listener
# socket, with stdin/stdout wired to that connection. Reads the JSON payload
# written by notify-send.nu and shows a real desktop notification.
#
# @real_notify_send@ is substituted at build time with the libnotify binary's
# store path.

def main [] {
    let raw = (^cat | str trim)

    if ($raw | is-empty) {
        return
    }

    try {
        let payload = ($raw | from json)
        ^@real_notify_send@ $"[($payload.host)] ($payload.title)" $payload.body
    } catch {
        # Malformed/partial payload (e.g. a stray connection) -- ignore.
    }
}
