#
# Clanker ! Do not modify this file!
#
{ config, lib, pkgs, modulesPath, ... }:
{
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/2c1a9e86-5b82-4545-bea1-c1b6b688fdf8";
    fsType = "ext4";
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/6583-1C43";
    fsType = "vfat";
    options = [ "fmask=0022" "dmask=0022" ];
  };
  swapDevices = [ ];
}
