{ pkgs
, config
, lib
, user
, unstablePkgs
, claude-desktop
, flox
, ...
}:
let
  zshFWBook = builtins.filterSource (p: t: true) ./scripts/fwbook;
  zshFunctions = zshFWBook + "/functions.sh";
  openPorts = [
    8000
    8001
  ];

in
{
  # Skyg
  skyg = {
    user.enable = true;
    server.admin.enable = true;
    core.qemu.enable = true;
    nixos = {
      common.hardware = {
        sound.enable = true;
        pipewire.enable = true;
        laptop-power-mgr = {
          enable = true;
          enableLidMonitorMode = true;
          enableTempMonitor = true;
          disableLidSwitch = true;
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
          hyprland.enable = true;
          noctalia.enable = true;
          quickshell.enable = true;
          niri = {
            enable = true;
            touchscreen-gestures = {
              enable = true;
              touchOutput = "eDP-1";
            };
          };
        };
      };
      common.ssh-notify = {
        enable = true;
        role = "client";
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
  virtualisation.waydroid.enable = true;
  hardware.enableRedistributableFirmware = true;
  # QEMU emulation for building aarch64 (e.g. hl-pi1) locally instead of on-device
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
  # Tailscale
  services.tailscale.enable = true;
  services.tailscale.extraDaemonFlags = [ "--statedir=/var/lib/tailscale" ];
  # Desktop Env - DankGreeter
  programs.dank-material-shell.greeter = {
    enable = true;
    compositor.name = "niri";
    configHome = "/home/${user.name}";
  };
  # home manager - only configure if skyg.user.enable is true
  home-manager.users.${user.name} = lib.mkIf config.skyg.user.enable {
    # Add Functions
    programs.zsh.initContent = ''
      source ${zshFunctions}
    '';
    services.blueman-applet.enable = true;
  };
  # Firmware updater
  hardware.framework.enableKmod = true;
  services.fprintd.enable = true;
  # Touchscreen
  services.libinput = {
    enable = true;
  };
  # Graphics
  hardware.graphics = {
    enable = true;
  };
  # Yubikey
  services.yubikey-agent.enable = true;
  # Bluetooth
  hardware.bluetooth.settings.General = {
    ControllerMode = "bredr";
  };
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  # Packages
  environment.systemPackages =
    let
      gdk = pkgs.google-cloud-sdk.withExtraComponents (
        with pkgs.google-cloud-sdk.components;
        [
          gke-gcloud-auth-plugin
          kubectl
        ]
      );
    in
    (with pkgs; [
      # Improvement of Life
      grim
      slurp
      wl-clipboard
      tesseract
      imagemagick
      zbar
      curl
      translate-shell
      wl-screenrec
      ffmpeg
      gifski
      libusb1
      lshw
      jq

      # Work
      postgresql
      google-cloud-sdk
      awscli
      openfortivpn
      openfortivpn-webview
      openfortivpn-webview-qt
      nodejs

      # Emulation
      wineWow64Packages.stable
      winetricks
      wineWow64Packages.waylandFull

      # Video recording & editing
      obs-studio
      davinci-resolve
      grim
      slurp
      wl-clipboard
      tesseract
      imagemagick
      zbar
      curl
      translate-shell
      wl-screenrec
      ffmpeg
      gifski
      jq

      # Photo/video Editing
      krita
      gimp-with-plugins
      shotcut
      simple-scan # scanning photos

      # socials
      zoom-us
      betterdiscordctl
      discord
      signal-desktop

      # Languages
      python313
      python314
      uv
      cargo
      rustc
      go
      pipx
      rust-analyzer

      # Development
      vscode
      unstablePkgs.zed-editor-fhs
      devenv
      just
      rpi-imager
      rpiboot
      code-cursor-fhs
      nix-prefetch
      orca-slicer
      devcontainer
      gpu-screen-recorder
      flox.packages.${pkgs.stdenv.hostPlatform.system}.default

      # Run macos apps
      darling-dmg

      # password
      bitwarden-cli

      # documents
      onlyoffice-desktopeditors

      # Work
      gdk
      slack

      # IPhone Tethering
      libimobiledevice
      ifuse

      # Iphone Management
      idevicerestore # optional, to mount using 'ifuse'

      # coding agents
      claude-desktop
      grok-cli
      pi-coding-agent
      claude-code
      buzz-desktop
      bubblewrap


    ]);

  services.usbmuxd.enable = true;
  # Tether — iPhone ↔ Linux Wayland bridge
  programs.tether = {
    enable = true;
    wifi = {
      enable = true;
      openFirewall = true;
    };
    bluetooth = {
      enable = true;
      adapters = [ "hci0" ];
    };
  };
  services.flatpak.packages = [
    "com.cassidyjames.butler"
    "io.dbeaver.DBeaverCommunity"
    "com.google.Chrome"
    "dev.deedles.Trayscale"
  ];
  # Phone
  programs.kdeconnect.enable = true;
  # Gaming
  programs.steam = {
    enable = true;
    extest.enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
    gamescopeSession.enable = true;
  };
  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };
  # Ollama
  services.ollama = {
    enable = true;
    host = "0.0.0.0";
    port = 11434;
    package = pkgs.ollama-rocm;
    environmentVariables = {
      HSA_OVERRIDE_GFX_VERSION = "11.0.2";
    };
  };
  # # Display Managers
  services.xserver.videoDrivers = [
    "modesetting"
    "fbdev"
  ];
  # Family Storage
  fileSystems."/mnt/EightTerra/FamilyStorage" = {
    device = "tnas1.lab.internal:/mnt/EightTerra/FamilyStorage";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "noauto"
    ];
  };
  fileSystems."/mnt/EightTerra/k3s-cluster" = {
    device = "tnas1.lab.internal:/mnt/EightTerra/k3s-cluster";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "noauto"
    ];
  };
  fileSystems."/mnt/EightTerra/DownloadedTorrents" = {
    device = "tnas1.lab.internal:/mnt/EightTerra/DownloadedTorrents";
    fsType = "nfs";
    options = [
      "x-systemd.automount"
      "noauto"
    ];
  };
  programs.nh = {
    enable = true;
    flake = "/home/ari/nixos-setup";
    clean.enable = true;
  };
  # Firewall
  networking.firewall.allowedUDPPorts = openPorts;
  networking.firewall.allowedTCPPorts = openPorts;
  networking.firewall.extraCommands = ''
    iptables -I INPUT 1 -s 172.16.0.0/12 -p tcp -d 172.17.0.1 -j ACCEPT
    iptables -I INPUT 2 -s 172.16.0.0/12 -p udp -d 172.17.0.1 -j ACCEPT
  '';
  # random dev work
  networking.hosts = {
    "0.0.0.0" = [
      "auth.me.internal"
      "me.internal"
      "me.local"
      "api.me.internal"
    ];
    "127.0.0.1" = [
      "fwbook"
      "auth.me.internal"
      "me.internal"
      "me.local"
      "api.me.internal"
    ];
  };
}
