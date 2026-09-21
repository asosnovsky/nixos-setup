{ ... }:
{
  # Trust the lab internal CA on every machine (e.g. buzz.app.internal TLS).
  # The cert is created by `skyg ca init` (public certs in configs/pki/,
  # CA key encrypted in secrets/). Eval fails if the cert is missing —
  # run `skyg ca init` before rebuilding.
  security.pki.certificateFiles = [ ../../configs/pki/lab-ca.crt ];
}
