{ config, lib, ... }:
let cfg = config.skyg.server.timers;
in {
  options = {
    skyg.server.timers = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          script = lib.mkOption {
            type = lib.types.str;
          };
          OnCalendar = lib.mkOption {
            type = lib.types.str;
            default = "daily";
          };
        };
      });
      default = { };
    };
  };
  config = {
    systemd.timers = builtins.mapAttrs
      (
        name: value: {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = value.OnCalendar;
            Persistent = true;
            Unit = "${name}.service";
          };
        }
      )
      cfg;

    systemd.services = builtins.mapAttrs
      (
        name: value: {
          script = value.script;
          serviceConfig = {
            Type = "oneshot";
            User = "root";
          };
        }
      )
      cfg;
  };
}
