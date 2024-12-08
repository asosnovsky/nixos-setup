{ lib
, config
, pkgs
, ...
}:
let
  cfg = config.skyg.nixos.common.hardware.amdgpu;
in
{
  options.skyg.nixos.common.hardware.amdgpu = with lib; {
    enable = mkEnableOption "amdgpu";
  };

  config = lib.mkIf cfg.enable {
    boot.initrd.kernelModules = [ "amdgpu" ];
    services.xserver.videoDrivers = [ "amdgpu" ];
    hardware.graphics = {
      extraPackages = [ pkgs.amdvlk ];
      extraPackages32 = [ pkgs.driversi686Linux.amdvlk ];
    };
    environment.systemPackages = (with pkgs; [
      rocmPackages.rocm-smi
      rocmPackages.rpp
      rocmPackages.rocm-core
      rocmPackages.rocm-runtime
      rocmPackages.hipblas
      rocmPackages.llvm.clang
      amdgpu_top
      amdctl
    ]);
  };
}
