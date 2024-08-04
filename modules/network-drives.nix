{ ... }: {
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
}
