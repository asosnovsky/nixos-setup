{ config, pkgs, ... }:
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
  skyg = {
    gc.rootDays = 30;
    gc.userDays = 30;
    user.enable = true;
    nixos.common = {
      ssh-server.enable = true;
      containers.openMetricsPort = true;
    };
    server.exporters.enable = true;
    networkDrives = {
      enable = true;
      bigBox2.enable = false;
    };
  };
  # Nix binary cache server (bigbox2 is the cache store for all builds)
  services.nix-serve = {
    enable = true;
    secretKeyFile = "/home/ari/cache-keys/cache-priv-key.pem";
    port = ports.nixServe;
  };
  # bigbox2 is the cache itself — don't push builds back to itself.
  skyg.nixos.common.cachePush.enable = false;
  # firmware updater
  services.fwupd.enable = true;
  services.nfs.server = {
    enable = true;
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
