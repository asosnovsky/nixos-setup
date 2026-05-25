export def hm-actions [] {
    ["switch", "build"]
}

export def remote-cmds [] {
    ["test", "dry-activate", "run", "switch", "build"]
}

const REPO_ROOT = path self | path dirname | path dirname | path dirname

export def secret-names [] {
    cd $REPO_ROOT
    ls secrets/*.age | get name | each { |f| $f | path basename | str replace ".age" "" }
}
