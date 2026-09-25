{ pkgs, config, ... }:
{
  imports = [
    ./services.nix
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
          hyprland.configLink = {
            enable = true;
            mountAsSource = true;
          };
          quickshell.enable = true;
        };
      };
    };
  };

  programs.dank-material-shell = {
    enable = true;
    systemd = {
      enable = true;
      restartIfChanged = true;
    };
  };

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

  environment.systemPackages = with pkgs; [
    skygqts
    v4l-utils
    libcec
    playerctl
  ];

  services.flatpak.enable = true;
  services.flatpak.packages = [ "com.spotify.Client" ];

  programs.chromium.enable = true;
  programs.chromium.extraOpts.DeveloperToolsAvailability = 2;

  services.udev.extraRules = ''
    SUBSYSTEM=="cec", MODE="0664", TAG+="uaccess"
  '';
}
