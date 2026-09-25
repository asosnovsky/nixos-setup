{ ... }:
let
  ports = { nixServe = 5000; };
in
{
  services.nix-serve = {
    enable = true;
    secretKeyFile = "/home/ari/cache-keys/minipc1.lab.internal.private";
    port = ports.nixServe;
  };
}
