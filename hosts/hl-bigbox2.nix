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
  # services.nix-serve = {
  #   enable = true;
  #   secretKeyFile = "/home/ari/cache-keys/bigbox2.lab.internal.private";
  #   port = ports.nixServe;
  # };
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
