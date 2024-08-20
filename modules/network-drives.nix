{ lib
, config
, ...
}:
with lib;
let
  cfg = config.skyg.networkDrives;
in
{
  options = {
    skyg.networkDrives = {
      enabled = mkEnableOption
        "Network Drives";
    };
  };
  config = mkIf cfg.enabled {
    fileSystems."/mnt/EightTerra/DownloadedTorrents" = {
      device = "tnas1.lab.internal:/mnt/EightTerra/DownloadedTorrents";
      fsType = "nfs";
      options = [ "x-systemd.automount" "noauto" ];
    };

    fileSystems."/mnt/EightTerra/k3s-cluster" = {
      device = "tnas1.lab.internal:/mnt/EightTerra/k3s-cluster";
      fsType = "nfs";
      options = [ "x-systemd.automount" "noauto" ];
    };

    fileSystems."/mnt/EightTerra/NVR" = {
      device = "tnas1.lab.internal:/mnt/EightTerra/NVR";
      fsType = "nfs";
      options = [ "x-systemd.automount" "noauto" ];
    };

    fileSystems."/mnt/terra1/Data/apps" = {
      device = "terra1.lab.internal:/mnt/Data/apps";
      fsType = "nfs";
      options = [ "x-systemd.automount" "noauto" ];
    };
  };
}
