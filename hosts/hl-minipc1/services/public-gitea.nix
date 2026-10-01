{ config, ... }:
let
  app = config.skyg.internalNetworkingMap.apps.public-gitea;
  domain = "gitea.skyg.ca";
in
{
  skyg.nixos.common.container-services.public-gitea = {
    enable = true;
    autoUpdate.enable = true;
    networks.lan = config.skyg.nixos.common.containers.networks.ipvlanLab.compose;
    volumes.public-gitea-data = {
      driver = "local";
      driver_opts = {
        type = "nfs";
        o = "addr=tnas1.lab.internal,rw,nfsvers=4.0,nolock,hard,noatime";
        device = ":/mnt/SmallG/public-gitea-data";
      };
    };
    services.public-gitea = {
      image = "gitea/gitea:latest";
      networks.lan.ipv4_address = app.ip;
      environment = {
        GITEA_CUSTOM = "/data/custom";
        GITEA__server__DOMAIN = domain;
        GITEA__server__ROOT_URL = "https://${domain}/";
        GITEA__server__HTTP_PORT = "80";
        GITEA__service__DISABLE_REGISTRATION = "true";
      };
      volumes = [ "public-gitea-data:/data" ];
      files."/data/custom/templates/home.tmpl" =
        builtins.readFile ./public-gitea-home.tmpl;
    };
  };
}
