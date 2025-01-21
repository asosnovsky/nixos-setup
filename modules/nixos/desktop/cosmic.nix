{ config, lib, pkgs, ... }:
let
  cfg = config.skyg.nixos.desktop.cosmic;
in
{
  options = {
    skyg.nixos.desktop.cosmic = {
      enable = lib.mkEnableOption
        "Cosmic";
    };
  };
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.cosmic-icons
    ];
    services.desktopManager.cosmic.enable = true;
  };
}
