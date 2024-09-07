{ config, lib, pkgs, inputs, ... }:
let
  cfg = config.skyg.nixos.desktop.hyprland;
  hyprpkgs = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system};
in
{
  config = lib.mkIf cfg.enabled {
    programs.hyprland = {
      enable = true;
      package = hyprpkgs.hyprland;
      portalPackage = hyprpkgs.xdg-desktop-portal-hyprland;
      xwayland.enable = true;
      systemd.setPath.enable = true;
    };
    xdg.portal.extraPortals = [ hyprpkgs.xdg-desktop-portal-hyprland ];
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
