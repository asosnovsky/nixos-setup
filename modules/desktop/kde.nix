{ pkgs, ... }:
{
  services.desktopManager.plasma6.enable = true;
  services.desktopManager.plasma6.notoPackage = pkgs.fira-code;
}
