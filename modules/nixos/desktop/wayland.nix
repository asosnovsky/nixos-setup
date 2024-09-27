{ config, lib, pkgs, ... }:
let
  cfg = config.skyg.nixos.desktop;
in
{
  config = lib.mkIf cfg.enabled {
    # Flatpak
    environment.systemPackages = with pkgs; [
      wayland
      wayland-protocols
      wayland-utils
      xdg-desktop-portal-wlr
      xdg-desktop-portal-gtk
    ];
    programs.xwayland.enable = true;
    xdg.portal.enable = true;
  };
}
