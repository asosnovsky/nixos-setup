{ pkgs, config, ... }:
{
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
}
