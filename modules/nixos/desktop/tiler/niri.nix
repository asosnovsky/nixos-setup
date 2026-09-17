{ config
, lib
, pkgs
, skygUtils
, unstablePkgs
, ...
}:
let
  cfg = config.skyg.nixos.desktop.tiler.niri;
  bakedConfig = skygUtils.bakeConfig {
    configName = cfg.configLink.name;
    configType = "niri";
  };
in
{
  options = {
    skyg.nixos.desktop.tiler.niri = {
      enable = lib.mkEnableOption "niri";
      configLink = skygUtils.makeConfigLinkOptions {
        hostName = config.skyg.core.hostName;
        configType = "niri";
      };
    };
  };
  config = lib.mkIf cfg.enable {
    skyg.nixos.desktop.tiler.enable = true;
    programs.niri = {
      enable = true;
    };
    environment.systemPackages = with pkgs; [
      hypridle
      swayosd
      xwayland-satellite
      adwaita-icon-theme
      papirus-icon-theme
    ] ++ (lib.optionals cfg.configLink.mountAsSource [ bakedConfig ]);

    system.userActivationScripts.niriConfig = lib.mkIf cfg.configLink.enable {
      text = skygUtils.makeHyperlinkScriptToConfigs {
        filePath = "${cfg.configLink.name}/niri";
        targetPath = "niri";
        configSource =
          if cfg.configLink.mountAsSource then
            "${bakedConfig}"
          else
            "/home/${config.skyg.user.name}/nixos-setup/configs";
      };
    };

    # programs.dank-material-shell = {
    #   enable = true;
    #   dgop.package = unstablePkgs.dgop;
    #   systemd = {
    #     enable = true; # Systemd service for auto-start
    #     target = "niri.service";
    #     restartIfChanged = true; # Auto-restart dms.service when dankMaterialShell changes
    #   };
    # };
    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
      ];
    };

  };
}
