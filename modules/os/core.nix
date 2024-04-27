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
    zsh
    git
    vscode
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
    (import (fetchTarball "https://install.devenv.sh/latest")).default
  ];
  programs.tmux = {
    enable = true;
    clock24 = true;
  };
}
