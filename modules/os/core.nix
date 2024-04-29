{ user }:
{ pkgs, ... }:
{
  # Set your time zone.
  time.timeZone = "America/Toronto";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_CA.UTF-8";

  # System Packages
  programs.zsh.enable = true;
  programs.nix-ld.enable = true;
  services.flatpak.enable = true;
  environment.systemPackages = with pkgs; [
    # nix utils
    nix-index
    appimage-run
    nil
    cachix

    # shell tools
    zsh
    git
    usbutils
    wget
    htop

    # system utils
    nfs-utils

    # misc
    glib
    glibc
    glib-networking

    # docker
    docker-compose

    # printer
    system-config-printer
  ];
  services.xserver.excludePackages = with pkgs; [
    xterm
  ];
  programs.tmux = {
    enable = true;
    clock24 = true;
  };
}
