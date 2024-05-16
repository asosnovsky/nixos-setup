{ pkgs, ... }:
{
  services.desktopManager.plasma6.enable = true;
  services.desktopManager.plasma6.notoPackage = pkgs.fira-code;
  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    konsole
    elisa
    kate
  ];
  environment.systemPackages = with pkgs; [
    kdePackages.plasma-browser-integration
  ];
}
