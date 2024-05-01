{ user }:
{ pkgs, ... }:
{
  programs.hyprland = {
    enable = true;
  };
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
  };
  programs.waybar.enable = false;
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
    hyprlock
    hypridle
    hyprpaper
    # color picker
    hyprpicker
    # nwg-shell
    nwg-dock-hyprland
    nwg-launchers
    nwg-displays
    nwg-drawer
    nwg-panel
    gopsuinfo
    nwg-look
    nwg-menu
    nwg-bar
    # screenshots
    ## old
    grim
    swappy
    slurp
    ## new
    hyprshot
    # networking
    networkmanagerapplet
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
  programs.kdeconnect.enable = true;
  services.pipewire.wireplumber.enable = true;
  users.users.${user.name}.extraGroups = [
    "input"
  ];
}
