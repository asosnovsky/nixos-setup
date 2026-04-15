# ComfyUI Docker Configuration for NixOS with GPU support
#
# Usage:
#   skyg.nixos.server.services.comfyui = {
#     enable = true;
#     mode = "rocm";  # or "cuda"
#     port = 8188;
#     rocmOverrideGfx = "gfx1151";  # optional, for newer AMD GPUs
#   };
#
# Run ComfyUI with Docker (ROCm):
#   docker run -it --rm \
#     --device=/dev/kfd --device=/dev/dri \
#     --group-add video --group-add render \
#     -v /path/to/models:/app/models \
#     -v /path/to/output:/app/output \
#     -p 8188:8188 \
#     <comfyui-rocm-image>

{ lib, config, ... }:

let
  cfg = config.skyg.nixos.server.services.comfyui;
in
{
  options.skyg.nixos.server.services.comfyui = with lib; {
    enable = mkEnableOption "ComfyUI Docker support with GPU";

    mode = mkOption {
      type = types.enum [ "rocm" "cuda" ];
      default = "rocm";
      description = "GPU acceleration mode: 'rocm' for AMD GPUs, 'cuda' for NVIDIA GPUs";
    };

    port = mkOption {
      type = types.port;
      default = 8188;
      description = "Port for ComfyUI web interface";
    };

    openFirewall = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to open the firewall for ComfyUI";
    };
  };

  config = lib.mkIf cfg.enable {
    # Assertions for required configuration (shared across all modes)
    assertions = [
      {
        assertion = config.virtualisation.docker.enable;
        message = "ComfyUI Docker support requires Docker to be enabled (virtualisation.docker.enable = true)";
      }
      {
        assertion = config.hardware.graphics.enable;
        message = "ComfyUI Docker support requires graphics to be enabled (hardware.graphics.enable = true)";
      }
      {
        assertion = config.hardware.enableAllFirmware;
        message = "ComfyUI Docker support requires firmware to be enabled (hardware.enableAllFirmware = true)";
      }
    ];

    # Firewall rules
    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];
    networking.firewall.allowedUDPPorts = lib.mkIf cfg.openFirewall [ cfg.port ];
  };
}
