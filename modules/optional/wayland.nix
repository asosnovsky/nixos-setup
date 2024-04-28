{ pkgs, ... }:
{
  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.displayManager.lightdm.greeters.enso.enable = true;
  programs.xwayland.enable = true;
  environment.systemPackages = with pkgs; [
    wayland
    wayland-protocols
    wayland-utils
  ];
}
