{ config, ... }:
{
  skyg.nixos.common.container-services.scrypted = {
    enable = true;
    autoUpdate.enable = true;
    services.scrypted = {
      image = "ghcr.io/koush/scrypted";
      volumes = [
        "/var/run/dbus:/var/run/dbus"
        "/var/run/avahi-daemon/socket:/var/run/avahi-daemon/socket"
        "/opt/homelab/scrypted/db:/server/volume"
        "scrypted-nvr:/nvr"
      ];
      environment.SCRYPTED_NVR_VOLUME = "/nvr";
      network_mode = "host";
    };
    volumes.scrypted-nvr = {
      driver = "local";
      driver_opts = {
        type = "nfs";
        o = "addr=tnas1.lab.internal,rw,nfsvers=4.0,nolock,hard,noatime";
        device = ":/mnt/OneT/NVR";
      };
    };
  };
}
