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
        tiler = {
          enable = true;
          hyprland.enable = true;
          hyprland.configLink = {
            enable = true;
            mountAsSource = true;
          };
          quickshell = {
            enable = true;
          };
        };
      };
    };
  };

  # dms
  programs.dank-material-shell = {
    enable = true;
    systemd = {
      enable = true;
      restartIfChanged = true;
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
  services.displayManager.dms-greeter = {
    enable = true;
    compositor.name = "hyprland";
    configHome = "/home/${config.skyg.user.name}";
  };
  services.displayManager.autoLogin = {
    enable = true;
    user = config.skyg.user.name;
  };
  services.displayManager.defaultSession = "hyprland";

  # environment
  environment.systemPackages = with pkgs; [
    # my goodies
    skygqts
    # --- 4. CEC control over the Framework HDMI card ---
    v4l-utils
    libcec
  ];

  # Flatpaks
  services.flatpak.enable = true;
  services.flatpak.packages = [
    "com.spotify.Client"
  ];

  # Chromium Configuration
  programs.chromium.enable = true;
  programs.chromium.extraOpts = {
    "DeveloperToolsAvailability" = 2;
  };

  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
    extraConfig.pipewire-pulse."10-raop-discover" = {
      context.modules = [
        { name = "libpipewire-module-raop-discover"; }
      ];
    };
  };
  security.rtkit.enable = true;

  # Send audio to AirPlay speakers
  services.avahi.enable = true;

  # AirPlay receiver
  services.shairport-sync = {
    enable = true;
    arguments = "-o pw";
  };
}
