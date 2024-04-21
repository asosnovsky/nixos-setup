{ config, pkgs, ... }:
{
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
