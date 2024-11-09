{ config, lib, ... }:

let
  cfg = config.skyg.nixos.server.services.scrypted;
in
{
  options = {
    skyg.nixos.server.services.scrypted = {
      enable = lib.mkEnableOption
        "Enable Scrypted";
    };
  };

  config = lib.mkIf cfg.enable {
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
  };
}
