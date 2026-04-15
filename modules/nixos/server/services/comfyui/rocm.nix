{ lib, config, pkgs, ... }:

let
  cfg = config.skyg.nixos.server.services.comfyui;
  isRocm = cfg.enable && cfg.mode == "rocm";
in
{
  options.skyg.nixos.server.services.comfyui = with lib; {
    rocmOverrideGfx = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "gfx1151";
      description = "Override GFX version for ROCm (useful for newer AMD GPUs)";
    };
  };

  config = lib.mkIf isRocm {
    # ROCm-specific assertions
    assertions = [
      {
        assertion = builtins.elem "amdgpu" config.boot.initrd.kernelModules;
        message = "ComfyUI ROCm mode requires 'amdgpu' in boot.initrd.kernelModules";
      }
      {
        assertion = builtins.elem "amdgpu" config.services.xserver.videoDrivers;
        message = "ComfyUI ROCm mode requires 'amdgpu' in services.xserver.videoDrivers";
      }
      {
        assertion = config.hardware.amdgpu.opencl.enable;
        message = "ComfyUI ROCm mode requires hardware.amdgpu.opencl.enable = true";
      }
    ];

    # ROCm and AMD GPU packages
    environment.systemPackages = with pkgs; [
      rocmPackages.rocm-smi
      rocmPackages.rocminfo
      rocmPackages.rpp
      rocmPackages.rocm-core
      rocmPackages.rocm-runtime
      rocmPackages.hipblas
      rocmPackages.llvm.clang
      amdgpu_top
      amdctl
    ];

    # Environment variables for ROCm stability
    environment.variables = lib.mkMerge [
      {
        # Stability fix — SDMA is buggy on some AMD unified memory configurations
        HSA_ENABLE_SDMA = "0";
      }
      (lib.mkIf (cfg.rocmOverrideGfx != null) {
        HSA_OVERRIDE_GFX_VERSION = cfg.rocmOverrideGfx;
      })
    ];
  };
}
