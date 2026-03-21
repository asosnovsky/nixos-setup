{ config, pkgs, ... }:
let
ports = {
  nixServe = 5000;
};
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
    };
  };
  services.nix-serve = {
    enable = true;
    secretKeyFile = "/home/ari/cache-keys/bigbox2.lab.internal.private";
    port = ports.nixServe;
  };
  # firmware updater
  services.fwupd.enable = true;
}
