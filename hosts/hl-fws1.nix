{ pkgs, config, ... }:
{
  skyg = {
    user.enable = true;
    nixos = {
      common.ssh-server.enable = true;
      common.hardware = {
        sound.enable = true;
        pipewire.enable = true;
      };
      desktop = {
        enable = true;
        slimMode = true;
        tiler = {
          enable = true;
          hyprland.enable = true;
          hyprland.configLink = {
            enable = false;
            mountAsSource = true;
          };
        };
      };
    };
  };
  # firmware updater
  services.fwupd.enable = true;
  hardware.framework.enableKmod = true;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.tmp.useTmpfs = true;

  # Greeter
  programs.dank-material-shell.greeter = {
    enable = true;
    compositor.name = "hyprland";
    configHome = "/home/${config.skyg.user.name}";
  };
  services.displayManager.autoLogin = {
    enable = true;
    user = config.skyg.user.name;
  };
  services.displayManager.defaultSession = "hyprland";
}
