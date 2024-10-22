{ config, lib, pkgs, inputs, system, ... }:
let
  cfg = config.skyg.nixos.desktop.hyprland;
in
{
  config = lib.mkIf (cfg.enable && !cfg.useNWG) {
    home-manager.users.${config.skyg.user.name}.wayland.windowManager.hyprland = {
      enable = true;
      xwayland.enable = true;
      extraConfig = ''
        source = ~/.config/hypr/hyprland.d/*.conf
        debug:enable_stdout_logs = true
      '';
    };
    programs.hyprlock.enable = true;
    environment.systemPackages =
      (with pkgs; [
        # general utilities
        swappy # screenshot editor
        hyprshot # screenshots
        cliphist # clipboard manager
        gnome.nautilus # file manager
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
      ]);
    system.userActivationScripts.hyprlandMineConfig.text = ''
      ln -sfn "/home/${config.skyg.user.name}/nixos-setup/configs/hyprland/mine/hypr" "$HOME/.config/hypr"
      ln -sfn "/home/${config.skyg.user.name}/nixos-setup/configs/hyprland/mine/waybar" "$HOME/.config/waybar"
      ln -sfn "/home/${config.skyg.user.name}/nixos-setup/configs/hyprland/mine/nwg-bar" "$HOME/.config/nwg-bar"
      ln -sfn "/home/${config.skyg.user.name}/nixos-setup/configs/hyprland/mine/dunst" "$HOME/.config/dunst"
    '';
  };
}
