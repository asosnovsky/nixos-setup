{ config, lib, pkgs, ... }:
let
  cfg = config.skyg.nixos.desktop;
in
{
  config = lib.mkIf cfg.enable {
    # Flatpak
    services.flatpak.enable = true;
    services.flatpak.remotes = [
      {
        name = "flathub-beta";
        location = "https://flathub.org/beta-repo/flathub-beta.flatpakrepo";
      }
      {
        name = "flathub";
        location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      }
    ];
    # Mobile Connect
    programs.kdeconnect.enable = true;
    environment.systemPackages = with pkgs; [
      # General utils
      busybox
      gcc
      rofimoji # emoji picker
      feh # image viewer
      xdg-desktop-portal

      # copy to clipboard
      wl-clipboard-x11
      xclip

      # socials
      #slack
      zoom-us
      betterdiscordctl
      discord
      signal-desktop
      whatsapp-for-linux
      caprine-bin # facebook messenger

      # development
      vscode

      # mail
      thunderbird

      # password
      bitwarden-desktop

      # documents
      onlyoffice-bin_latest

      # video
      vlc
      vlc-bittorrent

      # terminal
      alacritty
      alacritty-theme

      # wine
      wineWowPackages.stable
      winetricks
      wineWowPackages.waylandFull

      # Video recording
      obs-studio
    ];
    programs.firefox = {
      enable = true;
    };
    home-manager.users.${config.skyg.user.name}.home.shellAliases = {
      open-image = "feh";
      open-file = "nautilus";
    };
  };
}
