{ config, lib, ... }:
let cfg = config.skyg.server.timers;
in {
  options = {
    skyg.server.timers = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        script = lib.mkOption {
          type = lib.types.str;
        };
        timerConfig = lib.mkOption {
          type = lib.types.submodule;
        };
      });
      default = { };
    };
  };
  config = lib.mkIf cfg.enable {
    systemd.timers."backup-jellyfin" = {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
        Unit = "backup-jellyfin.service";
      };
    };

    systemd.services."backup-jellyfin" = {
      script = ''
        set -eu
        ${pkgs.rsync}/bin/rsync -avpzP --delete /opt/jellyfin /mnt/terra1/Data/apps/
      '';
      serviceConfig = {
        Type = "oneshot";
        User = "root";
      };
    };
  };
}
