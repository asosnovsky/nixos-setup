use types.nu *
use profile.nu *
use helpers.nu *
export use remote.nu *
export use os.nu *
export use secrets.nu *
export use ca.nu *
export use buzz.nu *
export use pkgs.nu *
export use flake.nu *
export use build.nu *
export use render.nu *
export use hm.nu *
export use net.nu *

export def skyg [] {
    print $REPO_ROOT
    let subcmds = (help commands |
    		where name starts-with "skyg " |
    		each {|c| $c.name | split row " " | get 1 } |
    		uniq | str join ', ')
    print $"Subcommands: ($subcmds)"
    print "Run: skyg <subcommand> --help"
}

export def "skyg profiles" [only_remote: bool = false] {
    if $only_remote {
        valid_remote_profiles | print
    } else {
        valid_profiles | print
    }
}
