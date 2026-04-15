{ lib, config, pkgs, ... }:

let
  cfg = config.skyg.nixos.server.services.comfyui;
  isCuda = cfg.mode == "cuda";
in
{
  config = lib.mkIf (cfg.enable && isCuda) {
    # TODO: Add CUDA-specific assertions
    # assertions = [
    #   {
    #     assertion = config.hardware.nvidia.enable or false;
    #     message = "ComfyUI CUDA mode requires NVIDIA drivers to be enabled";
    #   }
    # ];

    # TODO: Add CUDA-specific packages
    # environment.systemPackages = with pkgs; [
    #   cudaPackages.cudatoolkit
    #   nvidia-docker
    # ];
  };
}
