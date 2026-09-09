{ config
, lib
, pkgs
, skygUtils
, hyprland
, ...
}:
let
  cfg = config.skyg.nixos.desktop.tiler.hyprland;
  system = pkgs.stdenv.hostPlatform.system;
  hyprlandPkg = hyprland.packages.${system}.hyprland;
  hyprlandPortal = hyprland.packages.${system}.xdg-desktop-portal-hyprland;
  bakedConfig = skygUtils.bakeConfig {
    configName = cfg.configLink.name;
    configType = "hypr";
  };
in
{
  options = {
    skyg.nixos.desktop.tiler.hyprland = {
      enable = lib.mkEnableOption "hyprland";
      configLink = skygUtils.makeConfigLinkOptions {
        hostName = config.skyg.core.hostName;
        configType = "hypr";
      };
      tools = {
        enable = lib.mkEnableOption "Hyprland shell tools (hypridle, wofi, rofi, grim, slurp, satty)";
      };
    };
  };
  config = lib.mkIf cfg.enable {
    skyg.nixos.desktop.tiler.enable = true;

    programs.hyprland = {
      enable = true;
      withUWSM = true;
      xwayland.enable = true;
      package = hyprlandPkg;
      portalPackage = hyprlandPortal;
    };
    programs.uwsm.enable = true;

    xdg.portal = {
      enable = true;
      extraPortals = [ hyprlandPortal ];
    };

    # wl-clipboard is always needed; the rest are opt-in so headless-style
    # configs (e.g. hl-pi1) don't pull the whole shell toolchain.
    environment.systemPackages = with pkgs; [
      wl-clipboard
    ] ++ (lib.optionals cfg.tools.enable [
      hypridle
      wofi
      rofi
      grim
      slurp
      satty
    ]) ++ (lib.optionals cfg.configLink.mountAsSource [ bakedConfig ]);

    # Symlink ~/.config/hypr -> configs/<configName>/hypr (host-specific).
    system.userActivationScripts.hyprlandConfig = lib.mkIf cfg.configLink.enable {
      text = skygUtils.makeHyperlinkScriptToConfigs {
        filePath = "${cfg.configLink.name}/hypr";
        targetPath = "hypr";
        configSource =
          if cfg.configLink.mountAsSource then
            "${bakedConfig}"
          else
            "/home/${config.skyg.user.name}/nixos-setup/configs";
      };
    };
  };
}
