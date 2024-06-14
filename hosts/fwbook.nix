{ user, dataDir ? "/mnt/Data" }:
{ pkgs, lib, ... }:
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
  fileSystems."${dataDir}" = {
    device = "/dev/sda1";
    fsType = "ext4";
    options = [ "users" "nofail" ];
  };
  hardware.bluetooth.settings.General = { ControllerMode = "bredr"; };
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.tmp.useTmpfs = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
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
    # host = "0.0.0.0";
    openFirewall = true;
  };
  # Display Managers
  services.xserver.videoDrivers = [ "displaylink" "modesetting" ];
  services.xserver.displayManager.sessionCommands = ''
    ${lib.getBin pkgs.xorg.xrandr}/bin/xrandr --setprovideroutputsource 2 0
  '';
  # Kernel
  boot.initrd.kernelModules = [ "amdgpu" "evdi" ];
  hardware.opengl.extraPackages = with pkgs; [ rocmPackages.clr.icd amdvlk ];
  # Add Functions
  home-manager.users.${user.name}.programs.zsh.initExtra = ''
    source ${zshFunctions}
  '';
}
