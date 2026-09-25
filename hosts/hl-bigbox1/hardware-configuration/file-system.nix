#
# Clanker ! Do not modify this file!
#
{ config, lib, pkgs, modulesPath, ... }:
{
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/6302dadf-57b7-4213-a7a5-2ba97f941e49";
    fsType = "ext4";
  };
  fileSystems."/mnt/Data" = {
    device = "/dev/disk/by-uuid/b1c83d70-4d81-4d0f-a61a-38a78b943bd8";
    fsType = "ext4";
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/BBF9-1744";
    fsType = "vfat";
    options = [ "fmask=0022" "dmask=0022" ];
  };
  swapDevices = [{
    device = "/var/lib/swapfile";
    size = 32 * 1024;
  }];
  zramSwap.enable = true;
}
