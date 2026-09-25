#
# Clanker ! Do not modify this file!
#
{ config, lib, modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/142c88f4-b1bc-4ed9-92ee-2c52cdfa4274";
    fsType = "ext4";
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/01FE-EDCC";
    fsType = "vfat";
  };
  fileSystems."/nix" = {
    device = "/dev/disk/by-uuid/ee4a60a8-b0d1-4f5c-a554-1d1d84c89e34";
    fsType = "ext4";
    neededForBoot = true;
    options = [ "noatime" ];
  };
  swapDevices = [ ];
}
