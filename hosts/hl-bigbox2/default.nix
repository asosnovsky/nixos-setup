{ lib, ... }:
{
  imports = [
    ./services
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
      containers.networks.ipvlanLab = {
        enable = true;
        parent = "enp3s0";
      };
      cachePush.enable = false;
    };
    server.exporters.enable = true;
    networkDrives = {
      enable = true;
      bigBox2.enable = false;
    };
  };
}
