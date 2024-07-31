{ user, dataDir ? "/mnt/Data", unstable }:
{ pkgs, lib, config, ... }:
let
  zshFWBook = builtins.filterSource (p: t: true) ../configs/fwbook;
  zshFunctions = zshFWBook + "/functions.sh";
in
{
  imports = [ ./fwbook.hardware-configuration.nix ];
  services.fwupd.enable = true;
  services.fwupd.package = (import
    (builtins.fetchTarball {
      url =
        "https://github.com/NixOS/nixpkgs/archive/bb2009ca185d97813e75736c2b8d1d8bb81bde05.tar.gz";
      sha256 = "sha256:003qcrsq5g5lggfrpq31gcvj82lb065xvr7bpfa8ddsw8x4dnysk";
    })
    { inherit (pkgs) system; }).fwupd;
  services.fprintd.enable = true;
  hardware.bluetooth.settings.General = { ControllerMode = "bredr"; };
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.tmp.useTmpfs = true;
  # Packages
  environment.systemPackages = with pkgs; [
    # Amd GPU Support
    rocmPackages.rocm-smi
    rocmPackages.rpp
    rocmPackages.rocm-core
    rocmPackages.rocm-runtime
    rocmPackages.hipblas
    rocmPackages.llvm.clang
    amdgpu_top
    amdctl
    # Display Libraries
    displaylink
    # python
    python312
  ];
  # Opengl
  hardware.opengl = {
    driSupport = true;
    driSupport32Bit = true;
    extraPackages = [ pkgs.amdvlk ];
    extraPackages32 = [ pkgs.driversi686Linux.amdvlk ];
  };
  # Gaming
  programs.gamescope.enable = true;
  programs.steam = {
    enable = true;
    extest.enable = true;
    gamescopeSession.enable = true;
  };
  # Ollama
  services.ollama = {
    enable = true;
    acceleration = "rocm";
    listenAddress = "0.0.0.0:11434";
    package = unstable.ollama;
  };
  # Brother Printer
  hardware.sane.brscan5.enable = true;
  # Display Managers
  services.xserver.videoDrivers =
    [ "displaylink" "modesetting" "amdgpu" "fbdev" ];
  services.xserver.displayManager.sessionCommands = ''
    ${lib.getBin pkgs.xorg.xrandr}/bin/xrandr --setprovideroutputsource 2 0
  '';
  # Kernel
  boot.kernelPackages = pkgs.linuxPackages_zen;
  boot.initrd.kernelModules = [ "amdgpu" "evdi" ];
  # Add Functions
  home-manager.users.${user.name}.programs.zsh.initExtra = ''
    source ${zshFunctions}
  '';
  environment.localBinInPath = true;
  homelab.nix.remote-builder.enable = true;
  # Advance Power Management
  powerManagement.powertop.enable = true;
  powerManagement.enable = true;
  services.thermald.enable = true;
  services.power-profiles-daemon.enable = false;
  services.tlp = {
    enable = true;
    settings = {
      TLP_DEFAULT_MODE = "BAT";
      TLP_PERSISTENT_DEFAULT = 1;

      CPU_BOOST_ON_BAT = 0;
      RUNTIME_PM_ON_BAT = "auto";
      PLATFORM_PROFILE_ON_AC = "balanced";
      PLATFORM_PROFILE_ON_BAT = "low-power";

      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";

      CPU_MIN_PERF_ON_AC = 0;
      CPU_MAX_PERF_ON_AC = 100;
      CPU_MIN_PERF_ON_BAT = 0;
      CPU_MAX_PERF_ON_BAT = 20;

      START_CHARGE_THRESH_BAT0 = 40; # and bellow it starts to charge
      STOP_CHARGE_THRESH_BAT0 = 97; # and above it stops charging
    };
  };
  services.auto-cpufreq.enable = true;
  services.auto-cpufreq.settings = {
    battery = {
      governor = "powersave";
      turbo = "never";
    };
    charger = {
      governor = "performance";
      turbo = "auto";
    };
  };
  # Logind
  services.logind = {
    lidSwitchExternalPower = "suspend-then-hibernate";
    lidSwitch = "suspend-then-hibernate";
    powerKey = "lock";
    extraConfig = ''
      HandlePowerKey=suspend-then-hibernate
      IdleAction=suspend-then-hibernate
      IdleActionSec=2m
    '';
  };
  systemd.sleep.extraConfig = "HibernateDelaySec=30m";
}
