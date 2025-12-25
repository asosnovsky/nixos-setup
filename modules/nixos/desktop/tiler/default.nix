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
      programs.hyprlock.enable = true;
      programs.nm-applet.enable = true;
      environment.systemPackages = with pkgs; [
        # Protocols and libraries
        xwayland-satellite
        libnotify
        # Notifications
        mako
        wofi
        rofi
        # Control Tools
        pavucontrol
        playerctl
        brightnessctl
        networkmanagerapplet
        blueman
        # Apps
        walker
        waybar
        nwg-bar
        gnome-calendar
        nautilus
        # Screen capture and recording tools
        (flameshot.override { enableWlrSupport = true; })
        grim
        slurp
        satty
        wf-recorder
      ];
    };
}
