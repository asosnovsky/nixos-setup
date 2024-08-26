{ config, lib, pkgs, ... }:
let
  cfg = config.skyg.nixos.desktop;
in
{
  config = lib.mkIf cfg.enabled {
    # Flatpak
    services.flatpak.enable = true;
    # Mobile Connect
    programs.kdeconnect.enable = true;
    environment.systemPackages = with pkgs; [
      # General utils
      busybox
      gcc
      rofimoji # emoji picker
      feh # image viewer

      # copy to clipboard
      wl-clipboard-x11
      xclip

      # socials
      slack
      zoom-us
      betterdiscordctl
      discord
      signal-desktop
      whatsapp-for-linux
      caprine-bin # facebook messenger

      # development
      vscode

      # web
      brave

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
    home-manager.users.${config.skyg.user.name}.home.shellAliases = {
      open-image = "feh";
      open-file = "thunar";
    };
  };
}
