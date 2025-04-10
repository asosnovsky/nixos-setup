{ config, lib, pkgs, ... }:

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
    system.activationScripts = {
      scrypted-create-volume-nvr = {
        text = ''
          ${pkgs.docker}/bin/docker volume create \
            --driver local \
            --opt type=nfs \
            --opt o=addr=tnas1.lab.internal,rw,nfsvers=4.0,nolock,hard,noatime \
            --opt device=:/mnt/OneT/NVR \
            scrypted-nvr
        '';
        deps = [ ];
      };
    };
    skyg.server.timers = {
      scrypted-backups = {
        OnCalendar = "daily";
        wantedBy = [
          "mnt-terra1-Data-apps.mount"
        ];
        script = ''
          set -eu
          ${pkgs.rsync}/bin/rsync -avpzP --delete /opt/homelab/scrypted /mnt/terra1/Data/apps/
        '';
      };
      scrypted-autoupdate = {
        OnCalendar = "weekly";
        script = ''
          set -eu
          ${pkgs.docker}/bin/docker pull ghcr.io/koush/scrypted
          systemctl restart docker-scrypted.service
        '';
      };
    };
    virtualisation.oci-containers = {
      containers = {
        scrypted = {
          autoStart = false;
          image = "ghcr.io/koush/scrypted";
          extraOptions = [ "--network=host" ];
          volumes = [
            "/var/run/dbus:/var/run/dbus"
            "/var/run/avahi-daemon/socket:/var/run/avahi-daemon/socket"
            "/opt/homelab/scrypted/db:/server/volume"
            "scrypted-nvr:/nvr"
          ];
          environment = {
            SCRYPTED_NVR_VOLUME = "/nvr";
          };
        };
      };
    };
  };
}
