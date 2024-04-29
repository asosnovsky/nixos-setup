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
  environment.systemPackages = with pkgs; [
    nix-index
    zsh
    git
    nil
    docker-compose
    usbutils
    wget
    appimage-run
    htop
    nfs-utils
    cachix
    glib
    glibc
    glib-networking
    flatpak
  ];
  programs.tmux = {
    enable = true;
    clock24 = true;
  };
}
