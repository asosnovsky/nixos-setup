{ config, lib, pkgs, ... }:
let
  cfg = config.skyg.nixos.desktop.tiler;
in
{
  options = {
    skyg.nixos.desktop.tiler = {
      enable = lib.mkEnableOption
        "Enable libraries for tiling window managers";
    };
  };
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      mako
      brightnessctl
			libnotify
      fuzzel
      waybar
      pavucontrol
      sfwbar
      xwayland-satellite
    ];
  };
}
