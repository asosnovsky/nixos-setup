{ pkgs, ... }:
{
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.displayManager.gdm.wayland = true;
  programs.xwayland.enable = true;
  environment.systemPackages = with pkgs; [
    wayland
    wayland-protocols
    wayland-utils
  ];
}
