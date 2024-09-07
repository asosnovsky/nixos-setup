{ config, lib, pkgs, inputs, ... }:
let
  cfg = config.skyg.nixos.desktop.hyprland;
in
{
  config = lib.mkIf (cfg.enabled && !cfg.useNWG) {
    home-manager.users.${config.skyg.user.name}.wayland.windowManager.hyprland.plugins = [
      inputs.hyprspace.packages.${pkgs.system}.Hyprspace
    ];
    programs.hyprlock.enable = true;
    environment.systemPackages = with pkgs; [
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
      nwg-panel # top bar
      nwg-dock-hyprland # bottom bar
      nwg-displays # display management
      nwg-bar # logout window
    ];
    system.userActivationScripts.hyprlandMineConfig.text = ''
      rm "$HOME/.config/hypr"
      if [[ ! -h "$HOME/.config/hypr" ]]; then
        ln -s "/home/${config.skyg.user.name}/nixos-setup/configs/hyprland/mine/hypr" "$HOME/.config/hypr"
      fi
      rm "$HOME/.config/waybar"
      if [[ ! -h "$HOME/.config/waybar" ]]; then
        ln -s "/home/${config.skyg.user.name}/nixos-setup/configs/hyprland/mine/waybar" "$HOME/.config/waybar"
      fi
      rm "$HOME/.config/nwg-bar"
      if [[ ! -h "$HOME/.config/nwg-bar" ]]; then
        ln -s "/home/${config.skyg.user.name}/nixos-setup/configs/hyprland/mine/nwg-bar" "$HOME/.config/nwg-bar"
      fi
    '';
  };
}
