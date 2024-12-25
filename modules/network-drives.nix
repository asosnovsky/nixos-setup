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
      options = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "defaults" ];
      };
    };
  };
  config = lib.mkIf cfg.enable {
    fileSystems."/torrents" = {
      device = "tnas1.lab.internal:/mnt/EightTerra/DownloadedTorrents";
      fsType = "nfs";
      options = cfg.options;
    };

    fileSystems."/mnt/EightTerra/k3s-cluster" = {
      device = "tnas1.lab.internal:/mnt/EightTerra/k3s-cluster";
      fsType = "nfs";
      options = cfg.options;
    };

    fileSystems."/mnt/EightTerra/NVR" = {
      device = "tnas1.lab.internal:/mnt/EightTerra/NVR";
      fsType = "nfs";
      options = cfg.options;
    };

    fileSystems."/mnt/terra1/Data/apps" = {
      device = "terra1.lab.internal:/mnt/Data/apps";
      fsType = "nfs";
      options = cfg.options;
    };
  };
}
