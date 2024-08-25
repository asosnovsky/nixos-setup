{ config, lib, ... }:
with lib;

let
  cfg = config.skyg.nixos;
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
  config = mkIf cfg.desktop.enabled {
    services.displayManager.sddm.enable = false;
    services.displayManager.sddm.wayland.enable = false;
    services.xserver.displayManager.gdm.enable = true;
    services.xserver.displayManager.gdm.wayland = true;
  };
}
