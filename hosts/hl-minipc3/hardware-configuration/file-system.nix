#
# Clanker ! Do not modify this file!
#
{ config, lib, modulesPath, ... }:
{
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/5a468faa-b149-4ae2-9106-f0b5216d6d95";
    fsType = "ext4";
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/6CC4-8800";
    fsType = "vfat";
  };
  swapDevices = [{ device = "/dev/disk/by-uuid/e847bdf2-e049-428b-a203-8a1eae77ce56"; }];
}
