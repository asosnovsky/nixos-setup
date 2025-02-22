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
    security.rtkit.enable = true;
    environment.plasma6.excludePackages = with pkgs.kdePackages; [
      konsole # terminal
      elisa # media player
      kate # text editor
      gwenview # image viewer
    ];
    xdg.portal.extraPortals = [
      pkgs.kdePackages.xdg-desktop-portal-kde
      #   pkgs.kdePackages.kwallet
    ];
    environment.systemPackages = with pkgs; [
      konsave # save configs
    ];
    services.desktopManager.plasma6.notoPackage = pkgs.fira-code;
  };
}
