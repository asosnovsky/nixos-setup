{ config
, lib
, pkgs
, skygUtils
, ...
}:
let
  cfg = config.skyg.nixos.desktop.tiler.niri;
in
{
  imports = [
    ./niri-touchscreen-gestures.nix
  ];

  options = {
    skyg.nixos.desktop.tiler.niri = {
      enable = lib.mkEnableOption "niri";
      touchscreen-gestures = {
        enable = lib.mkEnableOption "touchscreen gesture support";
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
    ];
    system.userActivationScripts.niriConfig.text = skygUtils.makeHyperlinkScriptToConfigs {
      filePath = "niri";
      configSource = "/home/${config.skyg.user.name}/nixos-setup/configs";
    };
    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
      ];
    };

  };
}
