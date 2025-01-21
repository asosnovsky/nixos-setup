{ config, lib, pkgs, ... }:
let
  cfg = config.skyg.nixos.desktop;
in
{
  config = lib.mkIf cfg.enable
    {
      environment.sessionVariables.NIXOS_OZONE_WL = "1";
      environment.systemPackages = with pkgs; [
        # wayland
        # wayland-protocols
        wayland-utils
        # xdg-desktop-portal-wlr
        # xdg-desktop-portal-gtk
      ];
      programs.xwayland.enable = true;
      xdg.portal = {
        enable = true;
        xdgOpenUsePortal = true;
        extraPortals = with pkgs;[
          xdg-desktop-portal-gtk
          xdg-desktop-portal-wlr
          xdg-desktop-portal
        ];
      };
    };
}
