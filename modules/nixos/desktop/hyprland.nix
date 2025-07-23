{ config, lib, pkgs, ... }:
let
  cfg = config.skyg.nixos.desktop.hyprland;
  hyprPluginPkgs = inputs.hyprland-plugins.packages.${pkgs.system};
  hypr-plugin-dir = pkgs.symlinkJoin {
    name = "hyrpland-plugins";
    paths = with hyprPluginPkgs; [
      hyprexpo
      #...plugins
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
    environment.sessionVariables = { HYPR_PLUGIN_DIR = hypr-plugin-dir; };
  };
}
