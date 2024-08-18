{ pkgs, ... }:
{
  # Flatpak
  environment.systemPackages = with pkgs; [
    wayland
    wayland-protocols
    wayland-utils
  ];
  programs.xwayland.enable = true;
}
