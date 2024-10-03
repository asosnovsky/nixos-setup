{ config, lib, pkgs, ... }:
let
  cfg = config.skyg.nixos.desktop.kde;
in
{
  options = {
    skyg.nixos.desktop.kde = {
      enable = lib.mkEnableOption
        "KDE";
    };
  };
  config = lib.mkIf cfg.enable {
    services.desktopManager.plasma6.enable = true;
    services.desktopManager.plasma6.enableQt5Integration = true;
    environment.plasma6.excludePackages = with pkgs.kdePackages; [
      konsole # terminal
      elisa # media player
      kate # text editor
      gwenview # image viewer
    ];
    xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-kde ];
    environment.systemPackages = with pkgs; [
      kdePackages.plasma-browser-integration
      kdePackages.xdg-desktop-portal-kde
      konsave # save configs
    ];
    services.desktopManager.plasma6.notoPackage = pkgs.fira-code;
  };
}
