{ pkgs, ... }:
{
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  programs.xwayland.enable = true;
  environment.systemPackages = with pkgs; [
    wayland
    wayland-protocols
    wayland-utils
  ];
}
