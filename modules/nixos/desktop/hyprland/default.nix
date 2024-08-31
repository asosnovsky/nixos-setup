{ lib, ... }:
with lib;
{
  imports = [
    ./common.nix
    ./mine.nix
  ];
  options = {
    skyg.nixos.desktop.hyprland = {
      enabled = mkEnableOption
        "Hyprland";
      useNWG = mkEnableOption
        "nwg-shell experience";
    };
  };
}
