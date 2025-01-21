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
        cosmic.enable = true;
        kde.enable = true;
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
  services.displayManager.cosmic-greeter.enable = false;
  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
  services.displayManager.sddm.wayland.compositor = "kwin";

  # services.xserver.displayManager.gdm.enable = false;
  # services.xserver.displayManager.gdm.autoSuspend = false;
  # services.xserver.displayManager.gdm.banner = ''Ari's PC'';
  # services.xserver.displayManager.gdm.wayland = false;

  # services.displayManager.defaultSession = "plasmax11";
  # Firmware updater
  services.fwupd.enable = true;
  services.fwupd.package = (import
    (builtins.fetchTarball {
      url =
        "https://github.com/NixOS/nixpkgs/archive/bb2009ca185d97813e75736c2b8d1d8bb81bde05.tar.gz";
      sha256 = "sha256:003qcrsq5g5lggfrpq31gcvj82lb065xvr7bpfa8ddsw8x4dnysk";
    })
    { inherit (pkgs) system; }).fwupd;
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
  ]);
  # # Gaming
  programs.steam = {
    enable = true;
    extest.enable = true;
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
