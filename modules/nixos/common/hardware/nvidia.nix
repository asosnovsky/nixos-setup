{ lib
, config
, ...
}:
let
  cfg = config.skyg.nixos.common.hardware.nvidia;
in
{
  options.skyg.nixos.common.hardware.nvidia = with lib; {
    enable = mkEnableOption "nvidia";
  };

  config = lib.mkIf cfg.enable {
    boot.kernel.sysctl = {
      "net.core.bpf_jit_harden" = 1; # https://github.com/NVIDIA/libnvidia-container/issues/176#issuecomment-2101166824
    };
    # Nvidia Settings
    services.xserver.videoDrivers = [ "nvidia" ];
    hardware.nvidia-container-toolkit.enable = true;
    virtualisation.docker.enableNvidia = true;
    hardware.graphics.enable32Bit = true;
    hardware.graphics.enable = true;
    hardware.nvidia = {
      # datacenter.enable = true;
      modesetting.enable = true;
      powerManagement.enable = false;
      powerManagement.finegrained = false;
      open = false;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
  };
}
