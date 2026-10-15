use types.nu *
use helpers.nu *

# Render a Gitea HTML template and serve it locally for preview.
# Runs in the foreground — Ctrl+C to stop. Wrap it in nohup yourself to detach.
export def "skyg render html-tpl" [
    file: string@html-tpl-files  # Template to render (e.g. hosts/hl-minipc1/services/gitea-home.tmpl)
    --port: int = 8787           # Port for the local preview server
] {
    cd $REPO_ROOT
    let src = ($file | path expand)
    if not ($src | path exists) {
        error make {msg: $"Template not found: ($file)"}
    }

    let out_dir = ".tmp/render-html-tpl"
    mkdir $out_dir
    let name = ($src | path basename | str replace -r '\.tmpl$' '')
    let out = $"($out_dir)/($name).html"
    render-html-tpl $src $out

    print $"Rendered ($file) -> ($out)"
    print $"Preview: http://127.0.0.1:($port)/($name).html"
    print "Press Ctrl+C to stop."

    ^python3 -m http.server $port --bind 127.0.0.1 --directory $out_dir
}
