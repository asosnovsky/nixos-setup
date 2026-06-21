{ pkgs
, config
, lib
, user
, unstablePkgs
, noctalia
, hermes-agent
, ...
}:
let
  zshFWBook = builtins.filterSource (p: t: true) ./scripts/fwbook;
  zshFunctions = zshFWBook + "/functions.sh";
  openPorts = [
    8000
    8001
  ];
  noctaliaPkg = noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
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
          disableLidSwitch = true;
        };
        amdgpu.enable = true;
      };
      desktop = {
        enable = true;
        crypto.enable = true;
        tiler = {
          enable = true;
          niri.enable = true;
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
  virtualisation.waydroid.enable = true;
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
  # Fix robotic/distorted audio with AirPods over Bluetooth.
  # WirePlumber 0.5 (nixpkgs 26.05+) auto-switches BT devices from A2DP to
  # HFP whenever any app opens a mic stream (Chromium, Slack, etc.), which
  # degrades both speaker and mic quality to 8 kHz CVSD/mSBC and causes the
  # robotic sound. Disabling auto-switch keeps AirPods in A2DP permanently;
  # meeting apps fall back to the laptop's built-in mic for input.
  services.pipewire.wireplumber.extraConfig = {
    "51-airpods-bluetooth" = {
      "monitor.bluez.properties" = {
        "bluez5.msbc-support" = false;
        "bluez5.hfphsp-backend" = "native";
      };
      "wireplumber.settings" = {
        "bluetooth.autoswitch-to-headset-profile" = false;
      };
    };
  };
  nixpkgs.config.permittedInsecurePackages = [
    "python3.12-ecdsa-0.19.1"
  ];
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

      # Work
      postgresql
      google-cloud-sdk
      awscli
      openfortivpn
      openfortivpn-webview
      openfortivpn-webview-qt
      nodejs

      # Util
      libusb1

      # wine
      wineWowPackages.stable
      winetricks
      wineWowPackages.waylandFull
      lshw

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

      # Misc
      noctaliaPkg
      hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.desktop
      hermes-agent.packages.${pkgs.stdenv.hostPlatform.system}.default
    ]);
  services.usbmuxd.enable = true;
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
