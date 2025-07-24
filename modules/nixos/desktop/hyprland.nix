{ config, lib, pkgs, ... }:
let
  cfg = config.skyg.nixos.desktop.hyprland;
  hypr-plugin-dir = pkgs.symlinkJoin {
    name = "hyrpland-plugins";
    paths = with pkgs.hyprlandPlugins; [
      hyprexpo
      hyprbars
      hyprspace
    ];
  };
in
{
  options = {
    skyg.nixos.desktop.hyprland = {
      enable = lib.mkEnableOption
        "hyprland";
    };
  };
  config = lib.mkIf cfg.enable {
    skyg.nixos.desktop.tiler.enable = true;
    programs.hyprland = {
      enable = true;
      withUWSM = true;
    };
    programs.uwsm.enable = true;
    environment.systemPackages = with pkgs; [
      hyprls
    ];
    environment.sessionVariables = {
      HYPR_PLUGIN_DIR = hypr-plugin-dir;
    };
  };
}
