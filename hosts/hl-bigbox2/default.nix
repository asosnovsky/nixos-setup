{ config, lib, pkgs, ... }:
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
  imports = [
    ./services.nix
    ./hardware-configuration
    ./hardware.nix
  ];

  boot.loader.grub.device = lib.mkForce "/dev/disk/by-id/ata-KINGSTON_SA400S37240G_50026B7785904215";
  programs.nh.clean.extraArgs = "--keep-since 30d --keep 5";

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

  skyg.nixos.common.cachePush.enable = false;
}
