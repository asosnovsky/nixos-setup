{ config, pkgs, lib, ... }:

let
  cfg = config.skyg.common.containers;
in
{
  config = lib.mkIf (cfg.runtime == "docker") {
    virtualisation.docker = {
      enable = true;
      autoPrune.enable = true;
      enableOnBoot = cfg.enableOnBoot;
      liveRestore = false;
      daemon.settings = {
        insecure-registries = cfg.localDockerRegistries;
      };
    };
    environment.systemPackages = with pkgs; [ docker-compose ];
    users.users.${config.skyg.user.name}.extraGroups = [ "docker" ];
    virtualisation.oci-containers.backend = "docker";
  };
}
