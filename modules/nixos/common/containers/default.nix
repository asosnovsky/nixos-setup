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
        description = "DOcker vs podman";
        type = types.str;
        default = "docker";
      };
      enableOnBoot = mkOption {
        type = types.boolean;
        default = false;
      };
      localDockerRegistries = mkOption {
        type = types.listOf types.str;
      };
    };
  };
}
