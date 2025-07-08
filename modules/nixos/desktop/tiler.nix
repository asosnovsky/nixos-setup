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
    users.users.${config.skyg.user.name} = {
      extraGroups = [
        "input"
      ];
    };
    # services.blueman.enable = true;
    # programs.nm-applet.enable = true;
    environment.systemPackages = with pkgs; [
      mako
      brightnessctl
      libnotify
      fuzzel
      waybar
      pavucontrol
      xwayland-satellite
      wofi
      rofi
      rofi-wayland
      networkmanagerapplet
      blueman
    ];
  };
}
