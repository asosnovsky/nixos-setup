{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    wineWowPackages.stable
    winetricks
    wineWowPackages.waylandFull
  ];
}
