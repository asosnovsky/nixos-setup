{ pkgs, ... }:
{
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.displayManager.sddm.wayland.enable = true;
  programs.xwayland.enable = true;
  environment.systemPackages = with pkgs; [
    wayland
    wayland-protocols
    wayland-utils
  ];
}
