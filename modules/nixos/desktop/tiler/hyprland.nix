{ config, lib, pkgs, ... }:
let
  cfg = config.skyg.nixos.desktop.tiler.hyprland;
  # hypr-plugin-dir = pkgs.symlinkJoin {
  #   name = "hyrpland-plugins";
  #   paths = with pkgs.hyprlandPlugins; [
  #     hyprexpo
  #     hyprbars
  #     hyprspace
  #   ];
  # };
in
{
  options = {
    skyg.nixos.desktop.tiler.hyprland = {
      enable = lib.mkEnableOption
        "hyprland";
    };
  };
  config = lib.mkIf cfg.enable {
    skyg.nixos.desktop.tiler.enable = true;
    programs.hyprland = {
      enable = true;
      withUWSM = true;
      xwayland.enable = true;
    };
    programs.uwsm.enable = true;
    environment.systemPackages = with pkgs; [
      hyprls
    ];
    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [ xdg-desktop-portal-hyprland ];
    };
    home-manager.users."${config.skyg.user.name}".wayland.windowManager.hyprland = {
      enable = true;
      plugins = with pkgs; [
        hyprlandPlugins.hyprexpo
        hyprlandPlugins.hyprbars
      ];
    };
  };
}
