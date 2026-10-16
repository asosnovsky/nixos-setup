{ config, ... }:
let
  version = "v3";
  app = config.skyg.internalNetworkingMap.apps.immich-ml;
in
{
  skyg.nixos.common.container-services.immich-ml = {
    enable = true;
    autoUpdate.enable = true;
    networks.lan = config.skyg.nixos.common.containers.networks.ipvlanLab.compose;
    volumes.model-cache = { };
    services.immich-machine-learning = {
      image = "ghcr.io/immich-app/immich-machine-learning:${version}-cuda";
      networks.lan.ipv4_address = app.ip;
      volumes = [ "model-cache:/cache" ];
      environment.NVIDIA_VISIBLE_DEVICES = "all";
      deploy.resources = {
        limits = {
          cpus = "4";
          memory = "16G";
        };
        reservations.devices = [
          {
            driver = "cdi";
            device_ids = [ "nvidia.com/gpu=all" ];
            capabilities = [ "gpu" ];
          }
        ];
      };
      restart = "always";
    };
  };
}
