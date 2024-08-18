# { config, lib, pkgs, ... }:
# with lib;

# let
# in
# {
#   options = {
#     skyg.desktop.kde = {
#       enabled = mkEnableOption
#         "KDE";
#     };
#   };
#   config = mkIf cfg.enabled {
#     services.desktopManager.plasma6.enable = true;
#     services.desktopManager.plasma6.notoPackage = config.skyg.desktop.fonts;
#     services.desktopManager.plasma6.enableQt5Integration = true;
#     environment.plasma6.excludePackages = with pkgs.kdePackages; [
#       konsole # terminal
#       elisa # media player
#       kate # text editor
#       gwenview # image viewer
#     ];
#     environment.systemPackages = with pkgs; [
#       kdePackages.plasma-browser-integration
#       konsave # save configs
#     ];
#   };
# }

{ pkgs, config, lib, ... }:
let
  cfg = config.skyg.nixos;
  defaultConfig = {
    # System Packages
    services.hydra.useSubstitutes = true;
    programs.dconf.enable = true;
    programs.nix-ld.enable = true;
    environment.systemPackages = with pkgs; [
      # nix utils
      appimage-run

      # shell tools
      git
      usbutils

      # system utils
      nfs-utils

      # misc
      glib-networking
      glib
      glibc

      # printer
      system-config-printer
    ];
    services.xserver.excludePackages = with pkgs; [
      xterm
    ];
    # Set your time zone.
    time.timeZone = "America/Toronto";

    # Select internationalisation properties.
    i18n.defaultLocale = "en_CA.UTF-8";

    # Storage Clean up
    services.cron = {
      enable = true;
      systemCronJobs = [
        "* 23 * * *       root    nix-collect-garbage --delete-older-than 1d"
        "* 23 * * *       ${config.skyg.user.name}   nix-collect-garbage --delete-older-than 1d"
      ];
    };
  };
in
{
  options = {
    skyg.nixos.enableServe = lib.mkEnableOption "Enable nix serve";
  };

  config = defaultConfig // (if cfg.enableServe then {
    services.nix-serve = {
      enable = true;
      port = 5000;
    };
  } else { });
}
