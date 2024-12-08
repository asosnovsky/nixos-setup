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
      # package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
  };
}
