{ lib
, config
, pkgs
, ...
}:
let
  cfg = config.skyg.nixos.common.hardware.fancontrol;
in
{
  options.skyg.nixos.common.hardware.fancontrol = with lib; {
    enable = mkEnableOption "fancontrol";
    configName = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "thinkpad";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [{
      assertion = cfg.configName != null; # only checked when enable = true
      message = "skyg.nixos.common.hardware.fancontrol: configName must be set when fancontrol is enabled";
    }];
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
