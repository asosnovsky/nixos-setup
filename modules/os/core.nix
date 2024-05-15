{ pkgs, ... }:
{
  # System Packages
  services.flatpak.enable = true;
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

    # printer
    system-config-printer
  ];
  services.xserver.excludePackages = with pkgs; [
    xterm
  ];
}
