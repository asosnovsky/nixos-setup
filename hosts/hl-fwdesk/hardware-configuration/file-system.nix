#
# Clanker ! Do not modify this file!
#
{ config, lib, pkgs, modulesPath, ... }:
{
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/e903eb56-160d-4b77-ba66-ef54a18207f2";
    fsType = "btrfs";
    options = [ "subvol=root" ];
  };
  fileSystems."/home" = {
    device = "/dev/disk/by-uuid/e903eb56-160d-4b77-ba66-ef54a18207f2";
    fsType = "btrfs";
    options = [ "subvol=home" ];
  };
  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/e903eb56-160d-4b77-ba66-ef54a18207f2";
    fsType = "btrfs";
    options = [ "subvol=nix" ];
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/1D9A-20EC";
    fsType = "vfat";
    options = [ "fmask=0022" "dmask=0022" ];
  };
  fileSystems."/data" = {
    device = "/dev/disk/by-uuid/f241ec6e-939c-4f10-bc72-3094b99de4eb";
    fsType = "btrfs";
    options = [ "subvol=data" ];
  };
  swapDevices = [ ];
}
