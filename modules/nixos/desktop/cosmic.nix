{ config, lib, ... }:
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
    services.desktopManager.cosmic.enable = true;
    # services.displayManager.cosmic-greeter.enable = true;  
  };
}
