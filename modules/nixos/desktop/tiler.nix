{ config, lib, pkgs, inputs, ... }:
let
  anyrun = inputs.anyrun.packages.${pkgs.stdenv.hostPlatform.system}.anyrun;
  cfg = config.skyg.nixos.desktop.tiler;
in
{
  options = {
    skyg.nixos.desktop.tiler = {
      enable = lib.mkEnableOption
        "Enable libraries for tiling window managers";
    };
  };
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      mako
      libnotify
      fuzzel
      anyrun
    ];
  };
}
