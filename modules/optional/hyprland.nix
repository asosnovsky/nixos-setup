{ pkgs, ... }:
{
  programs.hyprland.enable = true;
  programs.waybar.enable = true;
  environment.systemPackages = with pkgs; [
    kitty
    xdg-desktop-portal-hyprland
    dunst
    pavucontrol
  ];
  services.mpd.enable = true;
  services.pipewire.enable = true;
  services.pipewire.wireplumber.enable = true;
}
