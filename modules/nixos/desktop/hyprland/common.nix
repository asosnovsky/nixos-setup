{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.skyg.nixos.desktop.hyprland;
in
{
  config = mkIf cfg.enabled {
    programs.hyprland.enable = true;
    programs.hyprland.xwayland.enable = true;
    programs.hyprland.systemd.setPath.enable = true;
    services.hypridle.enable = true;
    # programs.hyprlock.enable = true;
    # programs.waybar.enable = true;
    environment.sessionVariables = { NIXOS_OZONE_WL = "1"; };
    environment.systemPackages = with pkgs; [
      # sound
      pavucontrol

      # notification daemon
      dunst
      libnotify

      # App Support
      xwaylandvideobridge
      lxqt.lxqt-policykit
      xdg-desktop-portal
      xdg-desktop-portal-hyprland

      # general utilities
      brightnessctl # brightness ctl
      networkmanagerapplet # networking
    ];
    # <Sound
    services.mpd.enable = true;
    services.pipewire.wireplumber.enable = true;
    users.users.${config.skyg.user.name}.extraGroups = [ "input" ];
    # Sound />
  };
}
