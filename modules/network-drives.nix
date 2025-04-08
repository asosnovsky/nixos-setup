{ lib
, config
, ...
}:
let
  cfg = config.skyg.networkDrives;
in
{
  options = {
    skyg.networkDrives = {
      enable = lib.mkEnableOption
        "Network Drives";
      tnasHost = lib.mkOption {
        type = lib.types.str;
        default = "tnas1.lab.internal";
      };
      terraHost = lib.mkOption {
        type = lib.types.str;
        default = "terra1.lab.internal";
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
    fileSystems."/torrents" = {
      device = "${cfg.tnasHost}:/mnt/EightTerra/DownloadedTorrents";
      fsType = "nfs";
      options = cfg.options;
    };

    fileSystems."/mnt/EightTerra/k3s-cluster" = {
      device = "${cfg.tnasHost}:/mnt/EightTerra/k3s-cluster";
      fsType = "nfs";
      options = cfg.options;
    };

    fileSystems."/mnt/OneT/NVR" = {
      device = "${cfg.tnasHost}:/mnt/OneT/NVR";
      fsType = "nfs";
      options = cfg.options;
    };

    fileSystems."/mnt/terra1/Data/apps" = {
      device = "${cfg.terraHost}:/mnt/Data/apps";
      fsType = "nfs";
      options = cfg.options;
    };
  };
}
