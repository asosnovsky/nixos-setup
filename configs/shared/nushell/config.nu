# Shared Nushell setup, linked to ~/.config/nushell/config.nu.

$env.config.show_banner = false
$env.GPG_TTY = (^tty | complete | get stdout | str trim)

# Prompt and completions: write their init files where Nushell autoloads them.
let autoload = ($nu.data-dir | path join "vendor" "autoload")
mkdir $autoload
if (which starship | is-not-empty) {
    ^starship init nu | save --force ($autoload | path join "starship.nu")
}
if (which carapace | is-not-empty) {
    ^carapace _carapace nushell | save --force ($autoload | path join "carapace.nu")
}

# direnv: load the directory's environment before each prompt
if (which direnv | is-not-empty) {
    $env.config.hooks.pre_prompt = (
        $env.config.hooks.pre_prompt?
        | default []
        | append {||
            ^direnv export json
            | from json --strict
            | default {}
            | items {|key, value|
                let value = do (
                    {
                        "PATH": {
                            from_string: {|s| $s | split row (char esep) | path expand --no-symlink }
                            to_string: {|v| $v | path expand --no-symlink | str join (char esep) }
                        }
                    }
                    | merge ($env.ENV_CONVERSIONS? | default {})
                    | get ([[value, optional, insensitive]; [$key, true, true] [from_string, true, false]] | into cell-path)
                    | if ($in | is-empty) { {|x| $x} } else { $in }
                ) $value
                return [ $key $value ]
            }
            | into record
            | load-env
        }
    )
}

alias cat = bat
alias la = eza -a
alias ll = eza -l
alias lla = eza -la
alias ls = eza
alias lt = eza --tree
alias open = xdg-open
