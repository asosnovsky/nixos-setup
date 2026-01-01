{ lib, ... }:

{
  imports = [
    ./docker.nix
    ./podman.nix
  ];
  options = {
    skyg.nixos.common.containers = {
      runtime = lib.mkOption {
        description = "Docker vs podman";
        type = lib.types.str;
        default = "docker";
      };
      enableOnBoot = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      localDockerRegistries = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "minipc1.lab.internal:5001" ];
      };
      metricsPort = lib.mkOption {
        type = lib.types.number;
        default = 9323;
      };
      openMetricsPort = lib.mkEnableOption "Open container metrics port";
    };
  };
}
