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
    device = "/dev/disk/by-uuid/ee4a60a8-b0d1-4f5c-a554-1d1d84c89e34";
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
  virtualisation.oci-containers = {
    backend = "docker";
    containers = {
      myevents-app = {
        autoStart = true;
        image = "localhost:5001/asosnovsky/myevents";
        extraOptions = [ "--gpus" "all" ];
        ports = [ "8000:80" ];
        cmd = [ "app" ];
        environmentFiles = [
          "/mnt/Data/myevents/app.env"
        ];
        dependsOn = [ "myevents-db" ];
      };
      myevents-cron = {
        autoStart = true;
        image = "localhost:5001/asosnovsky/myevents";
        cmd = [ "cron" ];
        environmentFiles = [
          "/mnt/Data/myevents/app.env"
        ];
        dependsOn = [ "myevents-db" ];
      };
      myevents-db = {
        autoStart = true;
        image = "docker.io/postgres";
        hostname = "myevents-db";
        environmentFiles = [
          "/mnt/Data/myevents/db.env"
        ];
        volumes = [
          "/mnt/Data/myevents/db:/var/lib/postgresql/data"
        ];
      };
    };
  };
}

