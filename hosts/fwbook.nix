{ user }:
{ pkgs, ... }:
let
  zshFWBook = builtins.filterSource (p: t: true) ./scripts/fwbook;
  zshFunctions = zshFWBook + "/functions.sh";
  openPorts = [
    8000
  ];
in
{
  imports = [ ./fwbook.hardware-configuration.nix ];
  # Skyg
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
      common.pritunl.enable = true;
      desktop = {
        enable = true;
        cosmic.enable = true;
        kde.enable = false;
        crypto.enable = true;
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
  # Desktop Env
  services.displayManager.cosmic-greeter.enable = false;
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.displayManager.defaultSession = "cosmic";
  # Firmware updater
  services.fwupd.enable = true;
  services.fprintd.enable = true;
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
  environment.systemPackages = (with pkgs; [
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
    google-chrome

    # Photo Editing
    krita
    gimp-with-plugins

    # socials
    zoom-us
    betterdiscordctl
    discord
    signal-desktop
    skypeforlinux

    # development
    vscode

    # mail
    thunderbird

    # password
    bitwarden-desktop
    bitwarden-cli

    # documents
    onlyoffice-bin_latest

  ]);
  services.flatpak.packages = [
    "com.slack.Slack"
    "com.spotify.Client"
    "com.cassidyjames.butler"
    "io.dbeaver.DBeaverCommunity"
    "it.fabiodistasio.AntaresSQL"
    "com.github.sdv43.whaler"
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
  # Add Functions
  home-manager.users.${user.name}.programs.zsh.initExtra = ''
    source ${zshFunctions}
  '';
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
      "auth.me.internal"
      "me.internal"
      "me.local"
      "api.me.internal"
    ];
  };
}
