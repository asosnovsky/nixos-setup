use types.nu *
use helpers.nu *

# List all secret names (same as `skyg secrets list`)
export def "skyg secrets" [] {
    skyg secrets list
}

# List all secret names
export def "skyg secrets list" [] {
    secret-names
}

# Decrypt a secret from secrets/ folder
export def "skyg secrets show" [secret: string@secret-names] {
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
export def "skyg secrets edit" [
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
            print $"Fix the syntax, then re-run: skyg secrets edit ($secret) --yaml"
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
export def "skyg secrets compare" [secret: string@secret-names] {
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
