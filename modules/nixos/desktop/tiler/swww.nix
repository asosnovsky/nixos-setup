{ config, lib, pkgs, ... }:
let
  cfg = config.skyg.nixos.desktop.tiler;
in
{
  options = {
    skyg.nixos.desktop.tiler.background = {
      enable = lib.mkEnableOption
        "Enable background management for tiling window managers";
    };
  };
  config = lib.mkIf cfg.background.enable {
    environment.systemPackages = with pkgs; [
      swww
      waypaper
    ];
    systemd.user.services.waypaper = {
      description = "Waypaper Background Manager";
      path = [ pkgs.swww ];
      script = ''
        ${pkgs.waypaper}/bin/waypaper --restore
      '';
      wantedBy = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "oneshot";
      };
    };
  };
}
