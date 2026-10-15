use types.nu *
use helpers.nu *

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
    --for: string@ca-recipients  # secrets.nix key name allowed to decrypt the leaf key (e.g. minipc1)
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
