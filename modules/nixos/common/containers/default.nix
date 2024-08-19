{ lib, ... }:

with lib;

{
  imports = [
    ./docker.nix
    ./podman.nix
  ];
  options = {
    skyg.common.containers = {
      runtime = mkOption {
        description = "Docker vs podman";
        type = types.str;
        default = "docker";
      };
      enableOnBoot = mkOption {
        type = types.bool;
        default = false;
      };
      localDockerRegistries = mkOption {
        type = types.listOf types.str;
      };
    };
  };
}
