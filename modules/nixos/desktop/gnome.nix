{ config, lib, pkgs, ... }:
let
  cfg = config.skyg.nixos.desktop.gnome;
in
{
  options = {
    skyg.nixos.desktop.gnome = {
      enable = lib.mkEnableOption
        "gnome";
    };
  };
  config = lib.mkIf cfg.enable {
    services.xserver.desktopManager.gnome.enable = true;
    environment.gnome.excludePackages = with pkgs; [
      gnome-tour
      gnome-text-editor
      gnome-console
    ];
    environment.sessionVariables.GSK_RENDERER = "gl"; # fix blackbars around wayland windows
    environment.systemPackages = with pkgs; [ gnomeExtensions.pop-shell ];
    programs.dconf.enable = true;
    home-manager.users.${config.skyg.user.name}.dconf.settings = {
      "org/gnome/desktop/wm/keybindings" = {
        close = [ "<Super>q" ];
        maximize = [ "<Super>m" ];
        minimize = [ "<Super>n" ];
        move-to-monitor-right = [ "<Ctrl><Super>Right" ];
        move-to-monitor-left = [ "<Ctrl><Super>Left" ];
        move-to-workspace-last = [ "<Shift><Alt><Super>Right" ];
        move-to-workspace-left = [ "<Alt><Super>Left" ];
        move-to-workspace-right = [ "<Alt><Super>Right" ];
        switch-to-workspace-left = [ "<Super>Left" ];
        switch-to-workspace-right = [ "<Super>Right" ];
      };
    };
  };
}
