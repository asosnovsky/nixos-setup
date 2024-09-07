{ lib, ... }:
{
  imports = [
    ./common.nix
    ./mine.nix
    ./nwg-shell.nix
  ];
  options = {
    skyg.nixos.desktop.hyprland = with lib; {
      enabled = mkEnableOption
        "Hyprland";
      useNWG = mkEnableOption
        "nwg-shell experience";
    };
  };
}
