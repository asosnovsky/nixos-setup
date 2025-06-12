{ config, lib, ... }:
let
  cfg = config.skyg.nixos.desktop;
in
{
  imports = [
    ./lib-gesture.nix
  ];
  config = lib.mkIf cfg.enable {
    services.xserver = {
      enable = true;
      xkb.layout = "us";
      xkb.variant = "";
    };
  };
}
