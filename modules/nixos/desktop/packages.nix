{ config, lib, pkgs, inputs, ... }:
let
  cfg = config.skyg.nixos.desktop;
  ghostty = inputs.ghostty.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  config = lib.mkIf cfg.enable {
    # Flatpak
    services.flatpak.enable = true;
    # Mobile Connect
    programs.kdeconnect.enable = true;
    environment.systemPackages = [ ghostty ] ++ (with pkgs; [
      # General utils
      busybox
      gcc
      rofimoji # emoji picker
      feh # image viewer

      # copy to clipboard
      wl-clipboard-x11
      xclip

      # socials
      zoom-us
      betterdiscordctl
      discord
      signal-desktop
      skypeforlinux

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

      # Browser
      chromium
      google-chrome

      # Photo Editing
      krita
      gimp-with-plugins
    ]);
    services.flatpak.packages = [
      "com.slack.Slack"
      "com.spotify.Client"
      "com.cassidyjames.butler"
      "io.dbeaver.DBeaverCommunity"
      "it.fabiodistasio.AntaresSQL"
      "com.github.sdv43.whaler"
    ];
  };
}
