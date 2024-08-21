{ config, lib, ... }:
with lib;

let
  cfg = config.skyg.nixos.desktop;
in
{
  imports = [
    ./kde.nix
    ./hyprland.nix
    ./wayland.nix
    ./x11.nix
    ./packages.nix
  ];

  options = {
    skyg.nixos.desktop = {
      enabled = mkEnableOption
        "Enable Desktop";
    };
  };
  config = mkIf cfg.enabled {
    services.displayManager.sddm.enable = true;
    services.displayManager.sddm.wayland.enable = true;
  };
}
