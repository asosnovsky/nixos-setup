{ lib, ... }:
with lib;
{
  import = [
    ./mine.nix
    ./nwg-shell.nix
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
