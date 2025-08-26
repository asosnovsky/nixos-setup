{ config, lib, pkgs, ... }:
let
  cfg = config.skyg.nixos.desktop;
in
{
  config = lib.mkIf cfg.enable {
    # Flatpak
    services.flatpak.enable = true;
    environment.systemPackages = (with pkgs; [
      # General utils
      busybox
      gcc
      feh # image viewer
      eog # image viewer

      # copy to clipboard
      wl-clipboard-x11
      xclip

      # video
      vlc

      # terminal
      ghostty
    ]);
  };
}
