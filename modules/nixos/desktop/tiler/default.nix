{ config, lib, pkgs, ... }:
let
  cfg = config.skyg.nixos.desktop.tiler;
in
{
  imports = [
    ./hyprland.nix
    ./niri.nix
    ./swww.nix
  ];
  options = {
    skyg.nixos.desktop.tiler = {
      enable = lib.mkEnableOption
        "Enable libraries for tiling window managers";
    };
  };
  config = lib.mkIf cfg.enable
    {
      users.users.${config.skyg.user.name} = {
        extraGroups = [
          "input"
        ];
      };
      # services.blueman.enable = true;
      programs.nm-applet.enable = true;
      environment.systemPackages = with pkgs; [
        # Protocols and libraries
        xwayland-satellite
        libnotify
        # Notifications
        mako
        wofi
        rofi
        rofi-wayland
        # Control Tools
        pavucontrol
        brightnessctl
        networkmanagerapplet
        blueman
        # Apps
        fuzzel
        waybar
        nwg-bar
        # Screen capture and recording tools
        grim
        slurp
        satty
        wf-recorder
      ];
    };
}
