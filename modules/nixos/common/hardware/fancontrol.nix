{ lib
, config
, pkgs
, ...
}:
let
  cfg = config.skyg.hardware.fancontrol;
in
{
  options.skyg.hardware.fancontrol = with lib; {
    enable = mkEnableOption "fancontrol";
    configName = mkOption {
      type = types.str;
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.fancontrol = {
      enable = true;
      description = "Fan control";
      wantedBy = [ "multi-user.target" "graphical.target" "rescue.target" ];

      unitConfig = {
        Type = "simple";
      };

      serviceConfig = {
        ExecStart = "${pkgs.lm_sensors}/bin/fancontrol ${cfg.configName}";
        Restart = "always";
      };
    };
  };
}
