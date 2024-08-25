{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.skyg.nixos.desktop.hyprland;
in
{
  options = {
    skyg.nixos.desktop.hyprland = {
      enabled = mkEnableOption
        "Hyprland";
    };
  };
  config = mkIf cfg.enabled {
    programs.hyprland.enable = true;
    # programs.hyprland.xwayland.enable = true;
    programs.hyprland.systemd.setPath.enable = true;
    services.hypridle.enable = true;
    # services.xserver.windowManager.hypr.enable = true;
    programs.hyprlock.enable = true;
    programs.waybar.enable = true;
    environment.sessionVariables = { NIXOS_OZONE_WL = "1"; };
    environment.systemPackages = with pkgs; [
      # common utilities
      # mpv

      # sound
      pavucontrol

      # notification daemon
      dunst
      libnotify

      # App Support
      lxqt.lxqt-policykit
      xdg-desktop-portal
      xdg-desktop-portal-hyprland

      # color picker
      hyprpicker

      # general utilities
      swappy # screenshot editor
      hyprshot # screenshots
      cliphist # clipboard manager
      xfce.thunar # file manager
      wofi # app launcher
      wl-screenrec # screen recorder
      slurp # helper selection tools
      waypaper # wallpaper manager
      swww # wallpaper service
      waybar # top bar
      nwg-bar # logout window
      hypridle # idle watch
      brightnessctl # brightness ctl

      # networking
      networkmanagerapplet

    ];
    services.mpd.enable = true;
    services.pipewire.wireplumber.enable = true;
    users.users.${config.skyg.user.name}.extraGroups = [ "input" ];
    system.userActivationScripts.hyprlandlocalConfig.text = ''
      if [[ ! -h "$HOME/.config/hypr" ]]; then
        ln -s "/home/${config.skyg.user.name}/nixos-setup/configs/hypr" "$HOME/.config/hypr"
      fi
      if [[ ! -h "$HOME/.config/waybar" ]]; then
        ln -s "/home/${config.skyg.user.name}/nixos-setup/configs/waybar" "$HOME/.config/hypr"
      fi
    '';
  };
}
