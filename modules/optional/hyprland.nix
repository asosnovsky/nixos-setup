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
    xdg-desktop-portal
    # apps
    kitty
    # sound
    pavucontrol
    # notification daemon
    dunst
    libnotify
    # hyprland
    lxqt.lxqt-policykit
    xdg-desktop-portal-gtk
    xdg-desktop-portal-hyprland
    # screenshots
    grim
    swappy
    slurp
    # networking
    networkmanagerapplet
    libsForQt5.plasma-nm
    networkmanager_dmenu
    # waybar
    meson
    wl-clipboard
    wlroots
    cliphist
    xdg-desktop-portal-wlr
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
