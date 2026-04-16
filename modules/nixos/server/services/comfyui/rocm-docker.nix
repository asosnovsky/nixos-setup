# ComfyUI ROCm Docker Container Build and Service
#
# This module builds the ComfyUI container image and runs it as a systemd service
# using NixOS's OCI container abstraction.

{ lib, config, pkgs, ... }:

let
  cfg = config.skyg.nixos.server.services.comfyui;
  isRocm = cfg.enable && cfg.mode == "rocm";

  # Load Containerfile from file
  containerfile = ./rocm.Containerfile;
  containerinitsh = ./init.sh;

  # Image name and tag
  imageName = "nix-comfyui-rocm";
  imageTag = cfg.rocm.imageTag;
  fullImageName = "${imageName}:${imageTag}";
in
{
  options.skyg.nixos.server.services.comfyui.rocm = with lib; {
    uid = mkOption {
      type = types.int;
      default = 0;
      description = "User ID to run the ComfyUI container as";
    };

    gid = mkOption {
      type = types.int;
      default = 0;
      description = "Group ID to run the ComfyUI container as";
    };

    hsaOverrideGfxVersion = mkOption {
      type = types.str;
      default = "11.5.1";
      description = "HSA_OVERRIDE_GFX_VERSION for ROCm compatibility";
    };

    comfyuiCommit = mkOption {
      type = types.str;
      default = "master";
      description = "ComfyUI git commit or branch to checkout";
    };

    imageTag = mkOption {
      type = types.str;
      default = "latest";
      description = "Tag for the built ComfyUI ROCm image";
    };

    dataDir = mkOption {
      type = types.path;
      default = "/var/lib/comfyui";
      description = "Directory for ComfyUI data (models, output, etc.)";
    };

    modelsDir = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = "/mnt/models";
      description = "Optional external models directory to mount";
    };

    outputDir = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = "/mnt/output";
      description = "Optional external output directory to mount";
    };

    extraVolumes = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "/path/to/custom:/workspace/ComfyUI/custom_nodes/custom" ];
      description = "Additional volume mounts for the container";
    };

    autoStart = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to start the ComfyUI container automatically";
    };

    rebuildImage = mkOption {
      type = types.bool;
      default = false;
      description = "Force rebuild the Docker image on next activation";
    };
  };

  config = lib.mkIf isRocm {
    # Create data directories with proper ownership
    systemd.tmpfiles.rules = [
      "d ${cfg.rocm.dataDir} 0755 ${toString cfg.rocm.uid} ${toString cfg.rocm.gid} -"
      "d ${cfg.rocm.dataDir}/models 0755 ${toString cfg.rocm.uid} ${toString cfg.rocm.gid} -"
      "d ${cfg.rocm.dataDir}/models/checkpoints 0755 ${toString cfg.rocm.uid} ${toString cfg.rocm.gid} -"
      "d ${cfg.rocm.dataDir}/models/vae 0755 ${toString cfg.rocm.uid} ${toString cfg.rocm.gid} -"
      "d ${cfg.rocm.dataDir}/models/loras 0755 ${toString cfg.rocm.uid} ${toString cfg.rocm.gid} -"
      "d ${cfg.rocm.dataDir}/models/unet 0755 ${toString cfg.rocm.uid} ${toString cfg.rocm.gid} -"
      "d ${cfg.rocm.dataDir}/models/clip 0755 ${toString cfg.rocm.uid} ${toString cfg.rocm.gid} -"
      "d ${cfg.rocm.dataDir}/models/controlnet 0755 ${toString cfg.rocm.uid} ${toString cfg.rocm.gid} -"
      "d ${cfg.rocm.dataDir}/output 0755 ${toString cfg.rocm.uid} ${toString cfg.rocm.gid} -"
      "d ${cfg.rocm.dataDir}/custom_nodes 0755 ${toString cfg.rocm.uid} ${toString cfg.rocm.gid} -"
      "d ${cfg.rocm.dataDir}/user 0755 ${toString cfg.rocm.uid} ${toString cfg.rocm.gid} -"
      "d ${cfg.rocm.dataDir}/input 0755 ${toString cfg.rocm.uid} ${toString cfg.rocm.gid} -"
      "d ${cfg.rocm.dataDir}/temp 0755 ${toString cfg.rocm.uid} ${toString cfg.rocm.gid} -"
    ];

    # Build script for the Docker image
    system.activationScripts.comfyui-rocm-build = {
      text = ''
        # Check if image exists or rebuild is requested
        # Note: init.sh is located next to the Dockerfile, so it is automatically
        # included in the Docker build context and no explicit copy step is needed.
        if ! ${pkgs.docker}/bin/docker image inspect ${fullImageName} > /dev/null 2>&1 || ${lib.boolToString cfg.rocm.rebuildImage}; then
            # Create a temp build context with both files co-located
            BUILDCTX=$(mktemp -d)
            cp ${containerfile} "$BUILDCTX/rocm.Containerfile"
            cp ${containerinitsh} "$BUILDCTX/init.sh"
            chmod +x "$BUILDCTX/init.sh"

            echo "Building ComfyUI ROCm Docker image..."
            ${pkgs.docker}/bin/docker build \
              -t ${fullImageName} \
              --build-arg COMFYUI_COMMIT=${cfg.rocm.comfyuiCommit} \
              --build-arg HSA_OVERRIDE_GFX_VERSION=${cfg.rocm.hsaOverrideGfxVersion} \
              -f "$BUILDCTX/rocm.Containerfile" \
              "$BUILDCTX"

            rm -rf "$BUILDCTX"

        else
          echo "ComfyUI ROCm Docker image already exists, skipping build."
        fi
      '';
      deps = [ ];
    };

    # OCI container definition
    virtualisation.oci-containers.containers.comfyui = {
      autoStart = cfg.rocm.autoStart;
      image = fullImageName;

      ports = [
        "${toString cfg.port}:8188"
      ];

      # Run as user and ROCm GPU access
      user = "${toString cfg.rocm.uid}:${toString cfg.rocm.gid}";
      extraOptions = [
        "--device=/dev/kfd"
        "--device=/dev/dri"
        "--group-add=video"
        "--group-add=render"
        "--security-opt=seccomp=unconfined"
        "--ipc=host"
      ];

      environment = {
        HSA_OVERRIDE_GFX_VERSION = cfg.rocm.hsaOverrideGfxVersion;
        HSA_ENABLE_SDMA = "0";
        ROCBLAS_USE_HIPBLASLT = "1";
        PYTORCH_HIP_ALLOC_CONF = "expandable_segments:False";
      };

      volumes = [
        "${cfg.rocm.dataDir}/custom_nodes:/workspace/ComfyUI/custom_nodes"
        "${cfg.rocm.dataDir}/user:/workspace/ComfyUI/user"
        "${cfg.rocm.dataDir}/input:/workspace/ComfyUI/input"
        "${cfg.rocm.dataDir}/temp:/workspace/ComfyUI/temp"
      ] ++ (if cfg.rocm.modelsDir != null
      then [ "${cfg.rocm.modelsDir}:/workspace/ComfyUI/models" ]
      else [ "${cfg.rocm.dataDir}/models:/workspace/ComfyUI/models" ])
      ++ (if cfg.rocm.outputDir != null
      then [ "${cfg.rocm.outputDir}:/workspace/ComfyUI/output" ]
      else [ "${cfg.rocm.dataDir}/output:/workspace/ComfyUI/output" ])
      ++ cfg.rocm.extraVolumes;
    };

    # Ensure the container service starts after Docker image is built
    systemd.services."docker-comfyui" = {
      after = [ "docker.service" ];
      requires = [ "docker.service" ];
    };
  };
}
