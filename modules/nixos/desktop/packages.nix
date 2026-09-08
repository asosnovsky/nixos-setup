{ config, lib, pkgs, ... }:
let
  cfg = config.skyg.nixos.desktop;
in
{
  config = lib.mkIf cfg.enable {
    # Chrome
    programs.chromium = {
      enable = true;
      enablePlasmaBrowserIntegration = true;
      extensions = [
        "nngceckbapebfimnlniiiahkandclblb" # bitwarden
        "gcbommkclmclpchllfjekcdonpmejbdp" # https everywhere
        "cjpalhdlnbpafiamejdnhcphjbkeiagm" # ublock origin
      ];
    };
    # Flatpak
    environment.systemPackages = (with pkgs; [
      # Browser
      chromium
      # General utils
      busybox
      gcc
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
