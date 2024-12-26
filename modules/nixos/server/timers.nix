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
          wantedBy = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
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
          wantedBy = builtins.concatLists [
            [ "timers.target" ]
            value.wantedBy
          ];
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
