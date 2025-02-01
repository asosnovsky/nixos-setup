{ config, lib, pkgs, ... }:
let
  cfg = config.skyg.nixos.desktop;
in
{
  config = lib.mkIf cfg.enable
    {
      environment.sessionVariables.NIXOS_OZONE_WL = "1";
      environment.systemPackages = with pkgs; [
        wayland-utils
      ];
      programs.xwayland.enable = true;
      xdg.portal = {
        enable = true;
        xdgOpenUsePortal = true;
      };
    };
}
