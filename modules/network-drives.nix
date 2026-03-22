{ lib
, config
, ...
}:
let
  cfg = config.skyg.networkDrives;
  makeCommonOption = {defaultHost, enabledByDefault ? true} : lib.mkOption {
    type = lib.types.submodule {
      options = {
        enabled = lib.mkOption {
          type = lib.types.bool;
          default = enabledByDefault;
        };
        host = lib.mkOption {
          type = lib.types.str;
          default = defaultHost;
        };
      };
    };
    default = {
      enabled = enabledByDefault;
      host = defaultHost;
    };
  };
in
{
  options = {
    skyg.networkDrives = {
      enable = lib.mkEnableOption
        "Network Drives";
      tnas1 = makeCommonOption {
        defaultHost = "tnas1.lab.internal";
      };
      terra1 = makeCommonOption {
        defaultHost = "terra1.lab.internal";
      };
      bigBox2 = makeCommonOption {
        defaultHost = "bigbox2.lab.internal";
      };
      options = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "x-systemd.automount"
          "auto"
          "nofail"
          "_netdev"
        ];
      };
    };
  };
  config = lib.mkIf cfg.enable {
    fileSystems."/torrents" = lib.mkIf cfg.tnas1.enabled {
      device = "${cfg.tnas1.host}:/mnt/EightTerra/DownloadedTorrents";
      fsType = "nfs";
      options = cfg.options;
    };

    fileSystems."/mnt/EightTerra/k3s-cluster" = lib.mkIf cfg.tnas1.enabled {
      device = "${cfg.tnas1.host}:/mnt/EightTerra/k3s-cluster";
      fsType = "nfs";
      options = cfg.options;
    };

    fileSystems."/mnt/OneT/NVR" = lib.mkIf cfg.tnas1.enabled {
      device = "${cfg.tnas1.host}:/mnt/OneT/NVR";
      fsType = "nfs";
      options = cfg.options;
    };

    fileSystems."/mnt/terra1/Data/apps" = lib.mkIf cfg.terra1.enabled {
      device = "${cfg.terra1.host}:/mnt/Data/apps";
      fsType = "nfs";
      options = cfg.options;
    };
  };
}
