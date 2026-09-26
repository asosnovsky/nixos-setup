{ lib, pkgs, config, determinate, ... }:
{
  imports = [
    ./hardware-configuration
    ./hardware.nix
    ./systemd.nix
  ];

  skyg = {
    user.enable = true;
    nixos = {
      common.ssh-server.enable = true;
      common.hardware.pipewire.enable = true;
      desktop = {
        enable = true;
        tiler = {
          enable = true;
          hyprland.enable = true;
          hyprland.configLink.enable = false;
          noctalia.enable = false;
          quickshell.enable = true;
        };
      };
    };
  };

  nix.package = lib.mkForce (
    determinate.inputs.nix.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
      doCheck = false;
    })
  );

  programs.dms-greeter = {
    enable = true;
    compositor.name = "hyprland";
    configHome = "/home/${config.skyg.user.name}";
  };
  services.displayManager.autoLogin = {
    enable = true;
    user = config.skyg.user.name;
  };
  services.displayManager.defaultSession = "hyprland";

  environment.systemPackages = with pkgs; [ foot ];
}
