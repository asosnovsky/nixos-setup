#!/usr/bin/env nu

def pidfile [] {
    $"($env.XDG_RUNTIME_DIR? | default "/tmp")/hypr-speak.pid"
}

def pid-alive [pid: int] {
    (^kill -0 $pid | complete).exit_code == 0
}

def kill-tree [pid: int] {
    let kids = (^pgrep -P $pid | complete)
    if $kids.exit_code == 0 {
        for kid in ($kids.stdout | lines) {
            let kid = ($kid | str trim)
            if not ($kid | is-empty) {
                kill-tree ($kid | into int)
            }
        }
    }
    let _ = (^kill -KILL $pid | complete)
}

def main [] {
    let file = (pidfile)

    if ($file | path exists) {
        let old = (try { open --raw $file | str trim | into int } catch { null })
        rm --force $file
        if $old != null and (pid-alive $old) {
            kill-tree $old
            return
        }
    }

    let paste = (^wl-paste --primary | complete)
    if $paste.exit_code != 0 {
        return
    }

    let text = ($paste.stdout
        | str replace --all --regex '[\n\t]' ' '
        | str replace --all --regex "[^0-9A-Za-z .,!?'-]" ''
        | str replace --all --regex ' +' ' '
        | str trim)

    if ($text | is-empty) {
        return
    }

    $"($nu.pid)" | save --force $file
    try {
        $text | ^piper -m en_US-hfc_female-medium
    }
    rm --force $file
}
