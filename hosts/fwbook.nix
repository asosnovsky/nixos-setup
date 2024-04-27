{ user
, dataDir ? "/mnt/Data"
}:
{ pkgs, ... }:
{
  imports =
    [
      ./fwbook.hardware-configuration.nix
    ];
  services.fwupd.enable = true;
  fileSystems."${dataDir}" = {
    device = "/dev/sda1";
    fsType = "ext4";
    options = [
      "users"
      "nofail"
    ];
  };
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.tmp.useTmpfs = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;
  # Amd GPU Support
  environment.systemPackages = with pkgs; [
    rocmPackages.rocm-smi
    rocmPackages.rpp
    rocmPackages.rocm-core
    rocmPackages.rocm-runtime
    rocmPackages.hipblas
    rocmPackages.llvm.clang
    amdgpu_top
    amdctl
  ];
  boot.initrd.kernelModules = [ "amdgpu" ];
  hardware.opengl.extraPackages = with pkgs; [
    rocmPackages.clr.icd
    amdvlk
  ];
}
