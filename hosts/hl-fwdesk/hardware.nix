{ pkgs, ... }:
{
  boot.kernelPackages = pkgs.linuxPackages;
  boot.kernelParams = [
    "amd_iommu=off"
    "amdgpu.gttsize=126976"
    "ttm.pages_limit=32505856"
    "ttm.page_pool_size=32505856"
  ];
  hardware.enableAllFirmware = true;
  hardware.amdgpu.opencl.enable = true;

  services.fwupd.enable = true;
  skyg.nixos.common.hardware.bluetooth.enable = true;
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
}
