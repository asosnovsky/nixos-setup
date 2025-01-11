{ config, lib, pkgs, ... }:
let
  cfg = config.skyg.nixos;
in
{
  imports = [
    ./kde.nix
    ./cosmic.nix
    ./wayland.nix
    ./x11.nix
    ./packages.nix
    ./crypto.nix
  ];

  options = {
    skyg.nixos.desktop = {
      enable = lib.mkEnableOption
        "Enable Desktop";
    };
  };
  config = lib.mkIf cfg.desktop.enable {
    services.displayManager.enable = true;
    services.displayManager.sddm.enable = true;
    services.displayManager.sddm.wayland.enable = true;
    services.displayManager.sddm.wayland.compositor = "kwin";
    # security.pam.services.<name>.kwallet.enable = true;

    services.xserver.displayManager.gdm.enable = false;
    services.xserver.displayManager.gdm.autoSuspend = false;
    services.xserver.displayManager.gdm.banner = ''Ari's PC'';
    services.xserver.displayManager.gdm.wayland = false;
    xdg = {
      autostart.enable = true;
      mime.enable = true;
      menus.enable = true;
      icons.enable = true;
      sounds.enable = true;
      terminal-exec.enable = true;
      portal = {
        enable = true;
        # wlr.enable = true;
        # xdgOpenUsePortal = true;
        # config = {
        #   common.default = [ "*" ];
        #   plasma6.default = [ "gtk" "kde" ];
        # };
        # extraPortals = [
        #   pkgs.xdg-desktop-portal-gtk
        # ];
      };
    };
  };
}
