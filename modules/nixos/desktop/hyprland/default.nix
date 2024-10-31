{ lib, ... }:
{
  imports = [
    ./common.nix
    ./mine.nix
    ./nwg-shell.nix
  ];
  options = {
    skyg.nixos.desktop.hyprland = with lib; {
      enable = mkEnableOption
        "Hyprland";
      useNWG = mkEnableOption
        "nwg-shell experience";
      useDevelopmentMode = mkEnableOption
        "use the dev mode of hyprland";
    };
  };
}
