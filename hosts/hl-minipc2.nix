{}:
{ ... }: {
  imports = [ ./hl-minipc2.hardware-configuration.nix ];
  skyg.user.enable = true;
  skyg.nixos.common.ssh-server.enable = true;
  # firmware updater
  services.fwupd.enable = true;
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # Disable firewall
  networking.firewall.enable = false;
  # Special udev rule for google's coral tpu
  skyg.nixos.server.udevrules.coraltpu.enable = true;

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

