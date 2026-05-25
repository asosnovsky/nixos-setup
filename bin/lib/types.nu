const REPO_ROOT = path self | path dirname | path dirname | path dirname

export def hm-actions [] {
    ["switch", "build"]
}

export def remote-cmds [] {
    ["test", "dry-activate", "run", "switch", "build"]
}


export def secret-names [] {
    cd $REPO_ROOT
    glob secrets/*.age | each { |f| $f | path basename | str replace ".age" "" }
}
