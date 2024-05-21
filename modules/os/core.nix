{ user }:
{ pkgs, ... }:
{
  # System Packages
  services.hydra.useSubstitutes = true;
  services.flatpak.enable = true;
  services.nix-serve = {
    enable = true;
    port = 5000;
  };
  programs.dconf.enable = true;
  programs.nix-ld.enable = true;
  environment.systemPackages = with pkgs; [
    # nix utils
    appimage-run

    # shell tools
    git
    usbutils
    htop

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
      "* 23 * * *       ${user.name}   nix-collect-garbage --delete-older-than 1d"
    ];
  };
}
