{ config, ... }:
{
  skyg.nixos.common.container-services.drawdb = {
    enable = true;
    autoUpdate.enable = true;
    services.drawdb = {
      image = "ghcr.io/drawdb-io/drawdb:latest";
      environment.PORT = "80";
      networks.lan.ipv4_address = config.skyg.internalNetworkingMap.apps.drawdb.ip;
    };
    networks.lan = config.skyg.nixos.common.containers.networks.ipvlanLab.compose;
  };
}
