{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.skyg.nixos.cosmic.kde;
in
{
  options = {
    skyg.nixos.desktop.cosmic = {
      enabled = mkEnableOption
        "Cosmic";
    };
  };
  config = mkIf cfg.enabled {
    services.desktopManager.cosmic.enable = true;
    services.displayManager.cosmic-greeter.enable = true;
  };
}
