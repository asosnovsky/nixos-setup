{ user }:
{ pkgs, lib, config, ... }: {
  imports = [ ./hl-minipc2.hardware-configuration.nix ];
  skyg.user.enabled = true;
  # firmware updater
  services.fwupd.enable = true;
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Special udev rule for google's coral tpu
  skyg.homelab.udevrules.coraltpu.enable = true;

  # Containers
  virtualisation.oci-containers = {
    containers = {
      scrypted = {
        autoStart = true;
        image = "ghcr.io/koush/scrypted";
        extraOptions = [ "--network=host" ];
        volumes = [
          "/var/run/dbus:/var/run/dbus"
          "/var/run/avahi-daemon/socket:/var/run/avahi-daemon/socket"
          "/opt/homelab/scrypted/db:/server/volume"
          "/mnt/EightTerra/NVR:/nvr"
        ];
        environment = {
          SCRYPTED_NVR_VOLUME = "/nvr";
        };
      };
    };
  };
}

