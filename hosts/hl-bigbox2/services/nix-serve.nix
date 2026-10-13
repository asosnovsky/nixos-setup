{ ... }:
let
  ports = {
    nixServe = 5000;
  };
  openPorts = builtins.attrValues ports;
in
{
  services.nix-serve = {
    enable = true;
    secretKeyFile = "/home/ari/cache-keys/cache-priv-key.pem";
    port = ports.nixServe;
  };
  networking.firewall.allowedUDPPorts = openPorts;
  networking.firewall.allowedTCPPorts = openPorts;
}
