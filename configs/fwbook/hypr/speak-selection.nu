#!/usr/bin/env nu

let piperFolder = $env.HOME | path join ".local/share/piper"
let piperSoundCacheFolder = $env.HOME | path join ".local/share/piper-cache"
let modelName = "en_US-hfc_female-medium"

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
            let kid = $kid | str trim
            if not ($kid | is-empty) {
                kill-tree ($kid | into int)
            }
        }
    }
    let _ = (^kill -KILL $pid | complete)
}

def terminate-last [file: string] {
    if ($file | path exists) {
        let old = (
            try {
                open --raw $file | str trim | into int
            } catch { null }
        )
        rm --force $file
        if $old != null and (pid-alive $old) {
            kill-tree $old
            return true
        }
    }
    return false
}

# Show a failure notification. Works with `complete` results
# ({exit_code, stderr, ...}) and `catch` error records.
def notify-error [context: string, err: record] {
    let exit = $err | get -o exit_code
    let detail = if $exit != null {
        let stderr = $err | get -o stderr | default ""
        if ($stderr | is-empty) { $"exit ($exit)" } else { $"exit ($exit): ($stderr | str trim | lines | last)" }
    } else {
        $err.msg
    }
    let reply = notify-send -i dialog-error -A Yes="Copy to Clipboard" $"piper failed ($context)" $detail
    if $reply == "Yes" {
        ($err | get -o stderr | default "") | ^xclip
    }
}

def get-text [] {
    let paste = (^wl-paste --primary | complete)
    if $paste.exit_code != 0 {
        notify-send -i dialog-warning "Piper" "No text, make sure to copy something to clipboard"
        return
    }

    return ($paste.stdout
      | str replace --all --regex '[\n\t]' ' '
      | str replace --all --regex "[^0-9A-Za-z .,!?'-]" ''
      | str replace --all --regex ' +' ' '
      | str trim)
}

# returns true if failed
def run-tts [text: string, cache_file: string] {
    ^mkdir -p $piperSoundCacheFolder
    let res = (
        $text
        | ^piper -m $modelName --data-dir $piperFolder --output-file $cache_file
        | complete
    )
    if $res.exit_code != 0 {
        notify-error "piper" $res
        rm --force $cache_file
        return true
    }
    return false
}

def run-tts-pipeline [use_cache: bool, cache_file: string, text: string] {
    try {
        notify-send -i dialog-information $"Piper `($modelName)`" $"Text: ($text)"

        # skip piper when the audio is already cached
        if not ($use_cache and ($cache_file | path exists)) {
            if (run-tts $text $cache_file) {
                return
            }
        }
        if (play-file $cache_file) {
            return
        }
    } catch {|err| notify-error "unexpected" $err }

    # no caching → don't leave the audio file behind
    if not $use_cache {
        rm --force $cache_file
    }
}

# returns true if failed
def play-file [cache_file: string] {
    let res = (^ffplay -nodisp -autoexit $cache_file | complete)
    if $res.exit_code != 0 {
        notify-error "ffplay" $res
        return true
    }
    return false
}

def main [--cache] {
    let file = (pidfile)
    if (terminate-last $file) {
        notify-send -i dialog-information "Piper" "Stopped"
        return
    }
    let text = get-text

    if ($text | is-empty) {
        notify-send -i dialog-warning "Piper" "No text, make sure to copy something to clipboard"
        return
    }

    # cache key includes the model so different voices don't collide
    let text_sha = $"($modelName)|($text)" | hash sha256
    let cache_file = $piperSoundCacheFolder | path join $"($text_sha).wav"

    $"($nu.pid)" | save --force $file
    run-tts-pipeline $cache $cache_file $text
    rm --force $file
}
