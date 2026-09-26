{ config, ... }:
let
  nfsVolume = exportPath: {
    driver_opts = {
      type = "nfs";
      o = "addr=tnas1.lab.internal,rw,nfsvers=4.0,nolock,hard,noatime";
      device = ":${exportPath}";
    };
  };
  app = config.skyg.internalNetworkingMap.apps.audiobooks;
  audiobookshelf = {
    domain = app.effectiveDns;
    ip = app.ip;
    port = 80;
    image = "ghcr.io/advplyr/audiobookshelf:latest";
    dataDir = "/mnt/Data/audiobookshelf";
  };
in
{
  skyg.nixos.common.container-services.audiobookshelf = {
    enable = true;
    autoUpdate.enable = true;
    networks.lan = config.skyg.nixos.common.containers.networks.ipvlanLab.compose;
    volumes.books = nfsVolume "/mnt/EightTerra/DownloadedTorrents/books";
    services.audiobookshelf = {
      image = audiobookshelf.image;
      networks.lan.ipv4_address = audiobookshelf.ip;
      environment.PORT = toString audiobookshelf.port;
      volumes = [
        "${audiobookshelf.dataDir}/config:/config"
        "${audiobookshelf.dataDir}/metadata:/metadata"
        "books:/audiobooks"
        "${audiobookshelf.dataDir}/podcasts:/podcasts"
      ];
    };
  };
}
