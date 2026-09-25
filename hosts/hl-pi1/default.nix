{ lib, pkgs, config, determinate, ... }:
{
  imports = [
    ./hardware-configuration
    ./hardware.nix
    ./systemd.nix
  ];

  skyg.user.enable
    skyg = {
    user.enable = false;
    nixos = {
      common = {
        minimal = true;
        fonts.minimal = true;
        ssh-server.enable = true;
        containers.enable = false;
        networking.nfsServer.enable = false;
        hardware.pipewire.enable = true;
      };
      desktop = {
        enable = true;
        slimMode = true;
        tiler = {
          enable = true;
          hyprland.enable = true;
          hyprland.configLink = {
            enable = true;
            mountAsSource = true;
          };
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
