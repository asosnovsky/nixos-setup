{ config, lib, pkgs, ... }:
let
  cfg = config.skyg.nixos;
in
{
  imports = [
    ./cosmic.nix
    ./kde.nix
    ./wayland.nix
    ./x11.nix
    ./packages.nix
    ./crypto.nix
  ];

  options = {
    skyg.nixos.desktop = {
      enable = lib.mkEnableOption
        "Enable Desktop";
    };
  };
  config = lib.mkIf cfg.desktop.enable {
    services.displayManager.enable = true;
    xdg = {
      autostart.enable = true;
      mime.enable = true;
      menus.enable = true;
      icons.enable = true;
      sounds.enable = true;
      terminal-exec.enable = true;
      portal = {
        enable = true;
      };
    };
  };
}
