{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.skyg.nixos.desktop.hyprland;
in
{
  config = mkIf (cfg.enabled && cfg.useNWG) {
    programs.hyprlock.enable = true;
    environment.systemPackages = with pkgs; [
      # general utilities
      nwg-bar
      nwg-menu
      nwg-look
      nwg-dock
      nwg-panel
      nwg-hello
      nwg-drawer
      nwg-wrapper
      nwg-displays
      nwg-launchers
      nwg-dock-hyprland
    ];
  };
}
