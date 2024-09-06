{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.skyg.nixos.desktop.hyprland;
in
{
  config = mkIf cfg.enabled {
    programs.hyprland = {
      enable = true;
      portalPackage = pkgs.xdg-desktop-portal-hyprland;
      xwayland.enable = true;
      systemd.setPath.enable = true;
    };
    xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
    services.hypridle.enable = true;
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
      auto-cpufreq

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
