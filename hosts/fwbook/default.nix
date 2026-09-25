{ config, lib, user, ... }:
{
  imports = [
    ./hardware-configuration
    ./packages.nix
    ./services.nix
    ./networking.nix
    ./hardware.nix
    ./systemd.nix
  ];

  skyg = {
    user.enable = true;
    server.admin.enable = true;
    core.qemu.enable = true;
    nixos = {
      common.hardware = {
        pipewire.enable = true;
        laptop-power-mgr = {
          enable = true;
          enableTempMonitor = true;
        };
        amdgpu.enable = true;
      };
      desktop = {
        enable = true;
        crypto.enable = true;
        printers.enable = true;
        fixes = {
          airpod-bluetooth.enabled = true;
        };
        tiler = {
          enable = true;
          apps = {
            control.enable = true;
            gnome.enable = true;
            media.enable = true;
          };
          hyprland = {
            enable = true;
            tools.enable = true;
          };
          noctalia = {
            enable = true;
            configLink.enable = true;
          };
          quickshell.enable = true;
          niri = {
            enable = true;
            configLink.enable = false;
            touchscreen-gestures = {
              enable = true;
              touchOutput = "eDP-1";
            };
          };
        };
      };
    };
    networkDrives = {
      enable = false;
      options = [
        "x-systemd.automount"
        "noauto"
      ];
    };
  };

  nix.settings.cores = 4;
  nix.settings.max-jobs = 10;
  skyg.nixos.common.nh.flake = "/home/ari/nixos-setup";
  virtualisation.waydroid.enable = true;

  programs.dms-greeter = {
    enable = true;
    compositor.name = "niri";
    configHome = "/home/${user.name}";
  };

  services.usbmuxd.enable = true;

  home-manager.users.${user.name} = lib.mkIf config.skyg.user.enable (import ./home);
}
