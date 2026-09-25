{ ... }:
let
  ports = {
    nixServe = 5000;
    lockdPort = 4001;
    mountdPort = 4002;
    statdPort = 4000;
  };
  openPorts = builtins.attrValues ports;
in
{
  services.nix-serve = {
    enable = true;
    secretKeyFile = "/home/ari/cache-keys/cache-priv-key.pem";
    port = ports.nixServe;
  };

  skyg.nixos.common.networking.nfsServer.enable = true;
  services.nfs.server = {
    lockdPort = ports.lockdPort;
    mountdPort = ports.mountdPort;
    statdPort = ports.statdPort;
    extraNfsdConfig = '''';
    exports = ''
      /data/fourTerra  10.0.0.0/16(rw,wdelay,insecure,no_root_squash,no_subtree_check,sec=sys,rw,insecure,no_root_squash,no_all_squash)
    '';
  };

  networking.firewall.allowedUDPPorts = openPorts;
  networking.firewall.allowedTCPPorts = openPorts;
}
