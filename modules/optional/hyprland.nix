{ user }:
{ pkgs, ... }:
{
  programs.hyprland = {
    enable = true;
  };
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };
  programs.waybar.enable = true;
  environment.systemPackages = with pkgs; [
    # common utilities
    busybox
    scdoc
    mpv
    gcc
    # apps
    kitty
    # sound
    pavucontrol
    # notification daemon
    dunst
    libnotify
    # hypland
    lxqt.lxqt-policykit
    xdg-desktop-portal-gtk
    xdg-desktop-portal-hyprland
    # networking
    networkmanagerapplet
    # waybar
    meson
    wayland-protocols
    wayland-utils
    wl-clipboard
    wlroots
    # app launchers
    rofi-wayland
    wofi
  ];
  services.mpd.enable = true;
  services.pipewire.wireplumber.enable = true;
  users.users.${user.name}.extraGroups = [
    "input"
  ];
}
