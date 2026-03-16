{ config, pkgs, ... }:

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
    };
  };

  # firmware updater
  services.fwupd.enable = true;
}
