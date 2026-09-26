#
# Clanker ! Do not modify this file!
#
{ config, lib, pkgs, modulesPath, ... }:
{
  fileSystems."/" =
    {
      device = "/dev/disk/by-uuid/a3b275b4-96d4-4eb4-b01f-d80370899791";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/AAA7-BCE9";
      fsType = "vfat";
      options = [ "fmask=0022" "dmask=0022" ];
    };
  fileSystems."/mnt/Data" =
    {
      device = "/dev/sda1";
      fsType = "btrfs";
    };
  swapDevices = [ ];
}
