{ pkgs, ... }:
{
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;
  environment.systemPackages = with pkgs; [
    gnomeExtensions.vitals
  ];
  # Exclude Gnome packages
  environment.gnome.excludePackages = [
    pkgs.gnome-tour
    pkgs.gnome-console
  ];
}
