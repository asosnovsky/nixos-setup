use types.nu *
use profile.nu *
use helpers.nu *
export use remote.nu *

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

export def "skyg check" [] {
    nix flake check --no-build
}

# Validate that all versioned flake inputs use the same NixOS release
export def "skyg check-flake-versions" [] {
    let flake = "flake.nix"

    if not ($flake | path exists) {
        print "check-flake-versions: flake.nix not found, skipping"
        return
    }

    # Only scan url lines to avoid false positives from embedded script strings
    let url_lines = (open $flake | lines | enumerate | where { |row|
        ($row.item | str contains "url") and ($row.item =~ 'release-\d+\.\d+')
    })

    let versions = ($url_lines
        | each {|row| $row.item | parse --regex '.*release-(?P<version>\d+\.\d+).*' | get version }
        | flatten
        | uniq)

    if ($versions | length) <= 1 {
        print "check-flake-versions: OK"
        return
    }

    print "check-flake-versions: mismatched NixOS release versions in flake.nix:"
    print ""
    for version in $versions {
        print $"  release-($version):"
        $url_lines | where {|row| $row.item | str contains $"release-($version)" } | each { |row|
            print $"    line ($row.index + 1): ($row.item | str trim)"
        }
    }
    print ""
    print "All versioned inputs (home-manager, stylix, etc.) must use the same NixOS release."
    error make {msg: "Mismatched NixOS release versions"}
}

# rollback configuration
export def "skyg rollback" [] {
    sudo nixos-rebuild switch --rollback
}

# update some flakes
export def "skyg update" [input_name: string = ""] {
    cd $REPO_ROOT
    if $input_name == "" {
        print "Updating all flakes..."
        nix flake update | print
    } else {
        print $"Updating flake: ($input_name)"
        nix flake update $input_name | print
    }
    git diff flake.lock | print
}

# Build local os
export def "skyg os" [cmd: string, --build-host: string = ""] {
    cd $REPO_ROOT
    mut runcmd = $"nh os ($cmd)"
    if $build_host != "" {
        $runcmd = $"($runcmd) --build-host ($build_host).lab.internal"
    }
    $runcmd | print
    bash -c $runcmd
}

# Deploy OpenWrt router configuration
export def "skyg openwrt" [
    router: string = "glmain",
    --dry-run  # Render configs to .tmp/openwrt-<router>/ without touching the router
] {
    cd $REPO_ROOT
    let decrypted_file = skyg decrypt $"($router).json"
    if $dry_run {
        ^cat $decrypted_file | nix run .#openwrt-($router)-dry-run -- ($router)
    } else {
        ^cat $decrypted_file | nix run .#openwrt-($router)
    }
}

# Build a bootable image: ISO, or Pi SD card image (fully-baked, no on-device rebuild)
export def "skyg build-image" [target: string] {
    cd $REPO_ROOT
    let spec = (match $target {
        "iso" => { config: "iso", out: "iso", attr: "isoImage" }
        "pi1" => { config: "hl-pi1", out: "sd-image", attr: "sdImage" }
        "pi2" => { config: "hl-pi2", out: "sd-image", attr: "sdImage" }
        _ => { error make { msg: $"Unknown image target '($target)'. Expected: iso, pi1, pi2" } }
    })
    let imageBuildTime = date now | format date "%Y.%m.%d_%H_%M_%S"
    let rootOutputFolder = $REPO_ROOT | path join "build" $spec.config
    let outPutFolder = $rootOutputFolder | path join $imageBuildTime
    rm -rf $rootOutputFolder
    mkdir $rootOutputFolder
    nix build $"#nixosConfigurations.($spec.config).config.system.build.($spec.attr)" -o $outPutFolder
    printf $outPutFolder
}

# Home Manager operations
export def "skyg hm" [action: string, profile: string = "ari"] {
    cd $REPO_ROOT
    $"Running home-manager ($action) for profile ($profile)" | print
    home-manager $action --flake $".#($profile)"
}

# List all secret names
export def "skyg secrets" [] {
    secret-names
}

# Decrypt a secret from secrets/ folder
export def "skyg decrypt" [secret: string] {
    cd $REPO_ROOT
    let src = $"secrets/($secret).age"
    if not ($src | path exists) {
        error make {msg: $"Secret not found: ($src)"}
    }
    mkdir .tmp
    let dest = $".tmp/unencrypted-($secret)"
    agenix -d $src | save -f $dest
    print $"Decrypted to ($dest)"
    return $dest
}

# Encrypt a file to secrets/ folder (re-encrypts using agenix)
#   --yaml   Validate the content as YAML (via yq) before encrypting
export def "skyg encrypt" [
    secret: string@secret-names,
    source?: string,
    --yaml  # Validate the content as YAML (via yq) before encrypting
] {
    cd $REPO_ROOT
    let src = $source | default $".tmp/unencrypted-($secret)"
    if not ($src | path exists) {
        let encrypted = $"secrets/($secret).age"
        if ($encrypted | path exists) {
            agenix -d $encrypted | save -f $src
        } else {
            touch $src
        }
    }
    vi $src

    if $yaml {

        # `complete` captures stdout/stderr/exit_code; `try/catch` guards a missing yq
        let lint = (
            try {
                yq e '.' $src | complete
            } catch { null }
        )
        if $lint == null {
            print $"❌ Could not run yq — is it on PATH? Add 'yq' to the devShell in flake.nix."
            return
        }
        if $lint.exit_code != 0 {
            print $"❌ YAML validation failed for ($src):"
            print ($lint.stderr | str trim)
            print $"Fix the syntax, then re-run: skyg encrypt ($secret) --yaml"
            return
        }
        print $"✅ YAML valid: ($src)"
    }

    let dest = $"secrets/($secret).age"
    cat $src | agenix -e $dest
    print $"Encrypted ($dest)"
    return $dest
}

# Compare unencrypted local version with encrypted version of a secret
export def "skyg compare-secret" [secret: string@secret-names] {
    cd $REPO_ROOT
    let unencrypted = $".tmp/unencrypted-($secret)"
    let encrypted = $"secrets/($secret).age"

    let temp_decrypted = $"/tmp/skyg-compare-($secret)-($env.USER)-(random uuid)"
    agenix -d $encrypted | save -f $temp_decrypted
    print $"Comparing ($unencrypted) with decrypted ($encrypted)"
    try {
        print $"diff -u $(unencrypted) $(temp_decrypted)"
        diff -u $unencrypted $temp_decrypted | print
    } catch {
        print "Files are identical"
    }

    rm -f $temp_decrypted
}

# Generate the lab root CA: key encrypted to secrets/lab-ca-key.age,
# public cert written to configs/pki/lab-ca.crt. Run once, before `ca issue`.
export def "skyg ca init" [
    --days: int = 3650  # CA lifetime in days
] {
    cd $REPO_ROOT
    let cert = "configs/pki/lab-ca.crt"
    let key_secret = "secrets/lab-ca-key.age"
    if ($cert | path exists) {
        error make {msg: $"($cert) already exists — refusing to overwrite the CA. Delete it manually to rotate."}
    }
    ensure-secret-entry $key_secret ["ari"]
    mkdir .tmp configs/pki
    let tmp_key = ".tmp/lab-ca-key.pem"
    (openssl req -x509 -newkey rsa:4096 -sha256 -days $days -nodes
        -keyout $tmp_key -out $cert
        -subj "/CN=Skyg Lab CA"
        -addext "basicConstraints=critical,CA:TRUE"
        -addext "keyUsage=critical,keyCertSign,cRLSign")
    ^cat $tmp_key | agenix -e $key_secret
    rm -f $tmp_key
    print $"✅ CA cert: ($cert) — commit this"
    print $"✅ CA key encrypted: ($key_secret)"
    print "Next: skyg ca issue <domain> --for <host>"
}

# Issue a TLS cert for a domain, signed by the lab CA.
# Writes configs/pki/<domain>.crt; encrypts the key to secrets/<name>-tls-key.age.
export def "skyg ca issue" [
    domain: string          # e.g. buzz.app.internal
    --for: string           # secrets.nix key name allowed to decrypt the leaf key (e.g. minipc1)
    --days: int = 825       # leaf lifetime (825 = browser max)
    --name: string          # secret slug override (default: first DNS label)
] {
    cd $REPO_ROOT
    let ca_cert = "configs/pki/lab-ca.crt"
    let ca_key_secret = "secrets/lab-ca-key.age"
    if not ($ca_cert | path exists) {
        error make {msg: "No CA found — run `skyg ca init` first"}
    }
    let key_names = (^cat secrets.nix | parse --regex '(\w+) = "ssh-' | get capture0)
    if ($for not-in $key_names) {
        error make {msg: $"Unknown recipient '($for)'. Known: ($key_names | str join ', ')"}
    }
    let slug = $name | default ($domain | split row "." | first)
    let secret = $"secrets/($slug)-tls-key.age"
    let cert = $"configs/pki/($domain).crt"
    if ($cert | path exists) {
        error make {msg: $"($cert) already exists — delete it manually to re-issue."}
    }
    ensure-secret-entry $secret ["ari" $for]
    mkdir .tmp configs/pki
    let ca_key = ".tmp/lab-ca-key.pem"
    agenix -d $ca_key_secret | save -f $ca_key
    let leaf_key = $".tmp/($slug)-tls-key.pem"
    let csr = $".tmp/($slug).csr"
    let ext = $".tmp/($slug)-ext.cnf"
    $"basicConstraints=critical,CA:FALSE\nkeyUsage=critical,digitalSignature,keyEncipherment\nextendedKeyUsage=serverAuth\nsubjectAltName=DNS:($domain)\n" | save -f $ext
    (openssl req -newkey rsa:2048 -nodes
        -keyout $leaf_key -out $csr
        -subj $"/CN=($domain)")
    (openssl x509 -req -in $csr
        -CA $ca_cert -CAkey $ca_key -CAcreateserial
        -out $cert -days $days -sha256 -extfile $ext)
    ^cat $leaf_key | agenix -e $secret
    rm -f $ca_key $leaf_key $csr $ext
    print $"✅ Cert: ($cert) — commit this"
    print $"✅ Key encrypted: ($secret)"
    print $"Wire it up: age.secrets.($slug)-tls-key.file = ../($secret);"
}


# Update one or all packages. With a version, bumps explicitly.
# Without a version, auto-detects the latest from upstream.
#
#   skyg pkgs update --all
#   skyg pkgs update buzz-desktop
#   skyg pkgs update buzz-desktop 0.6.0
export def "skyg pkgs update" [
    pkg_name?: string@updatable-pkgs  # Package to update (omit with --all)
    version?: string                                 # Explicit version (omit for auto-detect)
    --all                                            # Update all packages that have update.sh
] {
    cd $REPO_ROOT

    if $all and $version != null {
        error make {msg: "Cannot use --all with a specific version. Run without --all to bump a single package."}
    }

    let targets = if $all {
        updatable-pkgs
    } else if $pkg_name != null {
        [$pkg_name]
    } else {
        error make {msg: "Specify a package name or use --all to update all packages"}
    }

    if ($targets | length) == 0 {
        print "No updatable packages found (no pkgs/*/update.sh scripts)"
        return
    }

    print $"Updating ($targets | length) package\(s): ($targets | str join ', ')"
    print ""

    for pkg in $targets {
        let update_script = $"pkgs/($pkg)/update.sh"
        if not ($update_script | path exists) {
            print $"⚠️  Skipping ($pkg) — no update.sh"
            continue
        }

        print $"=== ($pkg) ==="
        cd $"pkgs/($pkg)"
        try {
            if $version != null {
                bash $"update.sh ($version)" | print
            } else {
                bash "update.sh" | print
            }
        } catch { |e|
            print $"❌ Failed to update ($pkg): ($e)"
        }
        cd $REPO_ROOT
        print ""
    }

    print ""
    if $version != null {
        print "Bump complete. Review with:"
        git --no-pager diff pkgs/ | print
    } else {
        print "All updates complete. Review with:"
        git --no-pager diff pkgs/ | print
    }
}

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
