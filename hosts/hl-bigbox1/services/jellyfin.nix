{ config, ... }:
let
  app = config.skyg.internalNetworkingMap.apps.jellyfin;
in
{
  skyg.nixos.common.container-services.jellyfin = {
    enable = true;
    autoUpdate.enable = true;
    # networks = {
    #   lan = config.skyg.nixos.common.containers.networks.ipvlanLab.compose;
    # };
    services.jellyfin = {
      image = "jellyfin/jellyfin";
      deploy.resources.reservations.devices = [
        {
          driver = "cdi";
          device_ids = [ "nvidia.com/gpu=all" ];
          capabilities = [ "gpu" ];
        }
      ];
      volumes = [
        "/opt/jellyfin:/mnt/apps/jellyfin"
        "torrents:/torrents"
        "family-videos:/family-videos"
      ];
      # networks = {
      #   lan = {
      #     ipv4_address = app.ip;
      #   };
      # };
      devices = [ "/dev/dri:/dev/dri" ];
      restart = "always";
      healthcheck = {
        test = "curl --fail http://0.0.0.0:8096 || exit 1";
        interval = "60s";
        timeout = "20s";
        start_period = "30s";
      };
      environment = {
        JELLYFIN_DATA_DIR = "/mnt/apps/jellyfin/data";
        JELLYFIN_CACHE_DIR = "/mnt/apps/jellyfin/cache";
        JELLYFIN_CONFIG_DIR = "/mnt/apps/jellyfin/config";
        NVIDIA_VISIBLE_DEVICES = "all";
      };
      ports = [ "8096:8096" ];
    };
    volumes = {
      torrents = {
        driver_opts = {
          type = "nfs";
          o = "addr=tnas1.lab.internal,nfsvers=4";
          device = ":/mnt/EightTerra/DownloadedTorrents";
        };
      };
      family-videos = {
        driver_opts = {
          type = "nfs";
          o = "addr=tnas1.lab.internal,nfsvers=4";
          device = ":/mnt/EightTerra/FamilyStorage/Video";
        };
      };
      jellyfin = {
        driver_opts = {
          type = "nfs";
          o = "addr=tnas1.lab.internal,nfsvers=4";
          device = ":/mnt/Data/apps/jellyfin";
        };
      };
    };
  };
}
