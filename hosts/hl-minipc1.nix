{ user }:
{ pkgs, lib, config, ... }: {
  imports = [ ./hl-minipc1.hardware-configuration.nix ];
  # firmware updater
  services.fwupd.enable = true;
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # Data
  fileSystems."/mnt/Data" = {
    device = "/dev/sda1";
    fsType = "ext4";
    options = [ "nofail" ];
  };
  # Services
  homelab.services.audiobookshelf = {
    enable = true;
    host = "0.0.0.0";
    openFirewall = true;
    port = 8000;
    configDir = "/mnt/Data/audiobookshelf/config";
    metadtaDir = "/mnt/Data/audiobookshelf/metadata";
  };
  services.dockerRegistry = {
    enable = true;
    storagePath = "/mnt/Data/docker-registry";
    port = 5001;
    openFirewall = true;
    listenAddress = "0.0.0.0";
    enableDelete = true;
  };
}
