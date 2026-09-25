{ config, ... }:
{
  skyg.nixos.common.container-services.drawdb = {
    enable = true;
    autoUpdate.enable = true;
    services.drawdb = {
      image = "ghcr.io/drawdb-io/drawdb:latest";
      environment.PORT = "80";
      networks.lan.ipv4_address = "10.0.101.2";
      dns.names = [ "drawdb" ];
    };
    networks.lan = config.skyg.nixos.common.containers.networks.ipvlanLab.compose;
  };
}
