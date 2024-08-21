{ config, lib, ... }:
let
  cfg = config.skyg.nixos.desktop;
in
{
  config = lib.mkIf cfg.enabled {
    services.xserver = {
      enable = true;
      xkb.layout = "us";
      xkb.variant = "";
    };
  };
}
