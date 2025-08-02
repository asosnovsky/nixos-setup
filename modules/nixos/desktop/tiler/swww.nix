{ config, lib, pkgs, ... }:
let
  cfg = config.skyg.nixos.desktop.tiler;
in
{
  options = {
    skyg.nixos.desktop.tiler.background = {
      enable = lib.mkEnableOption
        "Enable background management for tiling window managers";
      imagePath = lib.mkOption {
        type = lib.types.path;
        description = "Path to the background image for tiling window managers.";
      };
    };
  };
  config = lib.mkIf cfg.background.enable {
    environment.systemPackages = with pkgs; [
      swww
      waytrogen
    ];
    systemd.user.services.swww = {
      description = "SWWW Background Manager";
      path = [ pkgs.swww ];
      script = ''
        ${pkgs.swww}/bin/swww-daemon
      '';
      wantedBy = [ "graphical-session.target" ];
      serviceConfig = {
        ExecStartPost = "${pkgs.swww}/bin/swww img ${cfg.background.imagePath} --resize no";
      };
    };
  };
}
