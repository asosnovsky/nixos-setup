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
    wireplumber.extraConfig."51-hdmi-tv" = {
      # Stop remembering the analog profile between boots — always prefer HDMI.
      "wireplumber.settings" = {
        "device.restore-profile" = false;
        "device.restore-routes" = false;
      };
      # ACP ranks analog-stereo (6565) above hdmi-stereo (5900) by default;
      # override that so the LG TV (hdmi-output-0, confirmed via ELD) wins.
      "device.profile.priority.rules" = [
        {
          matches = [{ "device.name" = "alsa_card.pci-0000_00_1f.3"; }];
          actions.update-props.priorities = [ "output:hdmi-stereo" ];
        }
      ];
      # Make the resulting HDMI sink win the default-sink vote too.
      "monitor.alsa.rules" = [
        {
          matches = [{ "node.name" = "~alsa_output.*hdmi.*"; }];
          actions.update-props."priority.session" = 2000;
        }
      ];
    };
  };
  security.rtkit.enable = true;

  # Let the logged-in session (not just root) open the CEC device, so
  # Hyprland can drive the TV without sudo.
  services.udev.extraRules = ''
    SUBSYSTEM=="cec", MODE="0664", TAG+="uaccess"
  '';

  # Disable auto-suspend/hibernate — always-on TV box
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

  # Send audio to AirPlay speakers
  services.avahi.enable = true;

  # AirPlay receiver
  services.shairport-sync = {
    enable = true;
    arguments = "-o pipewire";
  };
}
