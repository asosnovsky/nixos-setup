{ config, lib, pkgs, ... }:
let
  cfg = config.skyg.nixos;
in
{
  imports = [
    ./hyprland
    ./kde.nix
    ./cosmic.nix
    ./wayland.nix
    ./x11.nix
    ./packages.nix
    ./crypto.nix
  ];

  options = {
    skyg.nixos.desktop = {
      enabled = lib.mkEnableOption
        "Enable Desktop";
    };
  };
  config = lib.mkIf cfg.desktop.enabled {
    services.displayManager.sddm.enable = false;
    services.displayManager.sddm.wayland.enable = false;
    services.xserver.displayManager.gdm.enable = true;
    services.xserver.displayManager.gdm.wayland = true;
    xdg = {
      autostart.enable = true;
      mime.enable = true;
      menus.enable = true;
      icons.enable = true;
      sounds.enable = true;
      terminal-exec.enable = true;
      portal = {
        enable = true;
        wlr.enable = true;
        xdgOpenUsePortal = true;
        config = {
          common.default = [ "gtk" ];
          hyprland.default = [ "gtk" "hyprland" ];
          plasma6.default = [ "gtk" "kde" ];
        };
        extraPortals = [
          pkgs.xdg-desktop-portal-gtk
        ];
      };
    };
  };
}
