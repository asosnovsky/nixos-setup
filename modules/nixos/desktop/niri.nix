{ config, lib, pkgs, ... }:
let
  cfg = config.skyg.nixos.desktop.niri;
in
{
  options = {
    skyg.nixos.desktop.niri = {
      enable = lib.mkEnableOption
        "niri";
    };
  };
  config = lib.mkIf cfg.enable {
    skyg.nixos.desktop.tiler.enable = true;
    programs.niri = {
      enable = true;
      withUWSM = true;
    };
    programs.niri.enable = true;
    environment.systemPackages = with pkgs; [
      hypridle
    ];
  };
}
