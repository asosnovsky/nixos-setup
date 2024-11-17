{ user }:
{ ... }:
let
  openPorts = [
    5000
    5001
    8000
    22
  ];
in
{
  imports = [ ./hl-minipc1.hardware-configuration.nix ];
  skyg.user.enable = true;
  skyg.nixos.common.ssh-server.enable = true;
  skyg.nixos.common.containers.openMetricsPort = true;
  skyg.server.admin.enable = true;
  skyg.server.exporters.enable = true;

  # Nix Stores
  services.nix-serve = {
    enable = true;
    secretKeyFile = "/var/keys/cache-priv-key.pem";
    port = 5000;
  };
  # firmware updater
  services.fwupd.enable = true;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # Data
  fileSystems."/mnt/Data" = {
    device = "/dev/disk/by-uuid/ee4a60a8-b0d1-4f5c-a554-1d1d84c89e34";
    fsType = "ext4";
    options = [ "nofail" ];
  };
  # Services
  skyg.nixos.server.services.audiobookshelf = {
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
  # Firewall
  networking.firewall.allowedUDPPorts = openPorts;
  networking.firewall.allowedTCPPorts = openPorts;
}

