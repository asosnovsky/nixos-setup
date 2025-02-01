{ config, lib, pkgs, inputs, ... }:
let
  cfg = config.skyg.nixos.desktop;
  ghostty = inputs.ghostty.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  config = lib.mkIf cfg.enable {
    # Flatpak
    services.flatpak.enable = true;
    environment.systemPackages = [ ghostty ] ++ (with pkgs; [
      # General utils
      busybox
      gcc
      rofimoji # emoji picker
      feh # image viewer

      # copy to clipboard
      wl-clipboard-x11
      xclip

      # video
      vlc
    ]);
  };
}
