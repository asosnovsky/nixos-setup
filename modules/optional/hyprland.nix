{ user }:
{ pkgs, ... }:
{
  programs.hyprland.enable = true;
  programs.waybar.enable = true;
  environment.systemPackages = with pkgs; [
    kitty
    xdg-desktop-portal-hyprland
    dunst
    pavucontrol
    lxqt.lxqt-policykit
  ];
  services.mpd.enable = true;
  services.pipewire.enable = true;
  services.pipewire.wireplumber.enable = true;
  # security.polkit.enable = true;
  users.users.${user.name}.extraGroups = [
    "input"
  ];
  # systemd = {
  #   user.services.polkit-gnome-authentication-agent-1 = {
  #     description = "polkit-gnome-authentication-agent-1";
  #     wantedBy = [ "graphical-session.target" ];
  #     wants = [ "graphical-session.target" ];
  #     after = [ "graphical-session.target" ];
  #     serviceConfig = {
  #       Type = "simple";
  #       ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
  #       Restart = "on-failure";
  #       RestartSec = 1;
  #       TimeoutStopSec = 10;
  #     };
  #   };
  # };
}
