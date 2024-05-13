{ user
, dataDir ? "/mnt/Data"
}:
{ pkgs, lib, ... }:
{
  imports =
    [
      ./fwbook.hardware-configuration.nix
    ];
  services.fwupd.enable = true;
  services.fwupd.package = (import
    (builtins.fetchTarball {
      url = "https://github.com/NixOS/nixpkgs/archive/bb2009ca185d97813e75736c2b8d1d8bb81bde05.tar.gz";
      sha256 = "sha256:003qcrsq5g5lggfrpq31gcvj82lb065xvr7bpfa8ddsw8x4dnysk";
    })
    {
      inherit (pkgs) system;
    }).fwupd;
  services.fprintd.enable = true;
  fileSystems."${dataDir}" = {
    device = "/dev/sda1";
    fsType = "ext4";
    options = [
      "users"
      "nofail"
    ];
  };
  hardware.bluetooth.settings.General = {
    ControllerMode = "bredr";
  };
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
    displaylink
    amdgpu_top
    amdctl
  ];
  services.xserver.videoDrivers = [ "displaylink" "modesetting" ];
  services.xserver.displayManager.sessionCommands = ''
    ${lib.getBin pkgs.xorg.xrandr}/bin/xrandr --setprovideroutputsource 2 0
  '';
  boot.initrd.kernelModules = [ "amdgpu" "evdi" ];
  hardware.opengl.extraPackages = with pkgs; [
    rocmPackages.clr.icd
    amdvlk
  ];
}
