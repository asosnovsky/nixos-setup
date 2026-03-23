{ lib
, config
, ...
}:
let
  cfg = config.skyg.networkDrives;
  makeCommonOption = {
	  defaultHost,
	  enabledByDefault ? true
  } : lib.mkOption {
    type = lib.types.submodule {
      options = {
        enable = lib.mkOption {
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
      enable = enabledByDefault;
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
    fileSystems."/homelab/tnas1/torrents" = lib.mkIf cfg.tnas1.enable {
      device = "${cfg.tnas1.host}:/mnt/EightTerra/DownloadedTorrents";
      fsType = "nfs";
      options = cfg.options;
    };

    fileSystems."/homelab/tnas1/EightTerra/k3s-cluster" = lib.mkIf cfg.tnas1.enable {
      device = "${cfg.tnas1.host}:/mnt/EightTerra/k3s-cluster";
      fsType = "nfs";
      options = cfg.options;
    };

    fileSystems."/homelab/tnas1/OneT/NVR" = lib.mkIf cfg.tnas1.enable {
      device = "${cfg.tnas1.host}:/mnt/OneT/NVR";
      fsType = "nfs";
      options = cfg.options;
    };

    fileSystems."/homelab/terra1/Data/apps" = lib.mkIf cfg.terra1.enable {
      device = "${cfg.terra1.host}:/mnt/Data/apps";
      fsType = "nfs";
      options = cfg.options;
    };

    fileSystems."/homelab/bigbox2/data/fourTerra" = lib.mkIf cfg.bigBox2.enable {
      device = "${cfg.terra1.host}:/data/fourTerra";
      fsType = "nfs";
      options = cfg.options;
    };
  };
}
