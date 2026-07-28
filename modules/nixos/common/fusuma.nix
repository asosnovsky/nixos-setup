{ config, lib, pkgs, ... }:

let
  cfg = config.skyg.nixos.common.fusuma;
  configFile =
    if cfg.configFile != null then
      cfg.configFile
    else
      pkgs.writeText "fusuma-config.yml" (lib.generators.toYAML { } cfg.settings);
in
{
  options.skyg.nixos.common.fusuma = {
    enable = lib.mkEnableOption "Fusuma multi-touch gesture daemon (niri + per-app support)";

    package = lib.mkPackageOption pkgs "fusuma" { };

    settings = lib.mkOption {
      type = with lib.types; attrsOf anything;
      default = { };
      example = {
        swipe."3".left.command = "niri msg action FocusColumnRight";
        app.zed = {
          match.class = "dev.zed.Zed";
          swipe."2".left.keypress = { ALT = "press"; LEFT = "press"; };
        };
      };
      description = ''
        Fusuma configuration as a Nix attribute set.
        Converted to YAML and passed to the daemon.
      '';
    };

    configFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = "Path to an existing Fusuma config.yml (overrides generated settings)";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    # Ensure the user can read raw input devices
    users.users.${config.skyg.user.name}.extraGroups = lib.mkIf config.skyg.user.enable [ "input" ];

    systemd.user.services.fusuma = {
      description = "Fusuma multi-touch gesture daemon";
      partOf = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      wantedBy = [ "graphical-session.target" ];

      serviceConfig = {
        ExecStart = "${lib.getExe cfg.package} --daemon --config ${configFile}";
        Restart = "on-failure";
        RestartSec = 2;
      };
    };
  };
}
