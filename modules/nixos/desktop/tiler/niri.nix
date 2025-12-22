{
  config,
  lib,
  pkgs,
  skygUtils,
  system,
  nixpkgs-unstable,
  ...
}:
let
  cfg = config.skyg.nixos.desktop.tiler.niri;
  unstable = nixpkgs-unstable.legacyPackages.${system};
in
{
  options = {
    skyg.nixos.desktop.tiler.niri = {
      enable = lib.mkEnableOption "niri";
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
      # unstable.niriswitcher
    ];
    system.userActivationScripts.niriConfig.text = skygUtils.makeHyperlinkScriptToConfigs {
      filePath = "niri";
      configSource = "/home/${config.skyg.user.name}/nixos-setup/configs";
    };
    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
        xdg-desktop-portal-gnome
        gnome-keyring
      ];
    };
  };
}
