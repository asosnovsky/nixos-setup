{ user }:
{ pkgs, ... }:
let
  zshFWBook = builtins.filterSource (p: t: true) ./scripts/fwbook;
  zshFunctions = zshFWBook + "/functions.sh";
  openPorts = [
    8000
    8001
  ];
in
{
  imports = [ ./fwbook.hardware-configuration.nix ];
  # Skyg
  environment.sessionVariables.NIXPKGS_ALLOW_UNFREE = "true";
  environment.sessionVariables.COSMIC_DATA_CONTROL_ENABLED = 1;
  environment.sessionVariables.ELECTRON_OZONE_PLATFORM_HINT = "wayland";
  skyg = {
    user.enable = true;
    server.admin.enable = true;
    core.qemu.enable = true;
    nixos = {
      common.hardware = {
        sound.enable = true;
        pipewire.enable = true;
        laptop-power-mgr.enable = true;
        amdgpu.enable = true;
      };
      desktop = {
        enable = true;
        cosmic.enable = false;
        kde.enable = false;
        crypto.enable = true;
        gnome.enable = true;
        tiler = {
          enable = true;
          hyprland.enable = false;
          niri.enable = true;
          background = {
            enable = true;
          };
        };
      };
    };
    networkDrives = {
      enable = true;
      options = [
        "x-systemd.automount"
        "noauto"
      ];
    };
  };
  users.users.ari.extraGroups = [ "input" "disk" "wheel" "tty" "dialout" ];

  virtualisation.waydroid.enable = true;

  # Tailscale
  services.tailscale.enable = true;
  # Desktop Env
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.displayManager.gdm.wayland = true;
  services.displayManager.defaultSession = "niri";
  # home manager
  home-manager.users.${user.name} = {
    # Add Functions
    programs.zsh.initContent = ''
      source ${zshFunctions}
    '';
  };

  # Sunshine
  services.sunshine = {
    enable = false;
    autoStart = false;
    capSysAdmin = true;
    openFirewall = true;
  };

  # Firmware updater
  services.fwupd.enable = true;
  hardware.framework.enableKmod = true;
  services.fprintd.enable = true;
  hardware.framework.amd-7040.preventWakeOnAC = true;
  # Yubikey
  services.yubikey-agent.enable = true;
  # Enable CUPS to print documents.
  services.printing.enable = true;
  # Bluetooth
  hardware.bluetooth.settings.General = { ControllerMode = "bredr"; };
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.tmp.useTmpfs = true;
  # Packages
  environment.systemPackages =
    let
      gdk = pkgs.google-cloud-sdk.withExtraComponents
        (with pkgs.google-cloud-sdk.components; [
          gke-gcloud-auth-plugin
          kubectl
        ]);
    in
    (with pkgs; [
      # python
      python312
      # Work
      postgresql
      dvc-with-remotes
      google-cloud-sdk
      awscli

      # Util
      libusb1

      # wine
      wineWowPackages.stable
      winetricks
      wineWowPackages.waylandFull
      lshw

      # Video recording
      obs-studio

      # Browser
      chromium

      # Photo Editing
      krita
      gimp-with-plugins

      # socials
      zoom-us
      betterdiscordctl
      discord
      signal-desktop

      # development
      vscode
      devenv
      just
      rpi-imager

      # Run macos apps
      darling-dmg

      # mail
      thunderbird

      # password
      bitwarden-desktop
      bitwarden-cli

      # documents
      onlyoffice-bin_latest

      # Work
      gdk
      slack
      google-chrome

      # IPhone Tethering
      libimobiledevice
      ifuse

      # Iphone Management
      idevicerestore # optional, to mount using 'ifuse'
    ]);
  services.usbmuxd.enable = true;
  services.flatpak.packages = [
    "com.spotify.Client"
    "com.cassidyjames.butler"
    "io.dbeaver.DBeaverCommunity"
    "com.google.Chrome"
    "dev.deedles.Trayscale"
  ];
  # Gaming
  programs.steam = {
    enable = true;
    extest.enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
  };
  # Chrome
  programs.chromium = {
    enable = true;
    enablePlasmaBrowserIntegration = true;
    extensions = [
      "nngceckbapebfimnlniiiahkandclblb" # bitwarden
      "gcbommkclmclpchllfjekcdonpmejbdp" # https everywhere
      "cjpalhdlnbpafiamejdnhcphjbkeiagm" # ublock origin
    ];
  };
  # Ollama
  services.ollama = {
    enable = true;
    host = "0.0.0.0";
    port = 11434;
    acceleration = "rocm";
    rocmOverrideGfx = "11.0.2";
  };
  # # Brother Printer
  hardware.sane.brscan5.enable = true;
  # # Display Managers
  services.xserver.videoDrivers =
    [ "modesetting" "fbdev" ];
  # Kernel
  boot.kernelPackages = pkgs.linuxPackages_zen;

  environment.localBinInPath = true;
  # Family Storage
  fileSystems."/mnt/EightTerra/FamilyStorage" = {
    device = "tnas1.lab.internal:/mnt/EightTerra/FamilyStorage";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" ];
  };
  # Remote Builder
  nix.buildMachines = [{
    hostName = "root@bigbox1.lab.internal";
    system = "x86_64-linux";
    protocol = "ssh-ng";
    maxJobs = 1;
    speedFactor = 2;
    supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
    mandatoryFeatures = [ ];
  }];
  nix.distributedBuilds = true;
  # optional, useful when the builder has a faster internet connection than yours
  nix.extraOptions = ''
    builders-use-substitutes = true
  '';
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
