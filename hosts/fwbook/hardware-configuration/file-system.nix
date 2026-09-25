#
# Clanker ! Do not modify this file!
#
{ pkgs, ... }:
{
  fileSystems."/" =
    {
      device = "/dev/disk/by-uuid/adaad601-f79c-4342-ba3a-9eab53ec4cd1";
      fsType = "btrfs";
      options = [ "subvol=@root" "compress=zstd" ];
    };

  fileSystems."/root-btrfs" =
    {
      device = "/dev/disk/by-uuid/adaad601-f79c-4342-ba3a-9eab53ec4cd1";
      fsType = "btrfs";
    };

  fileSystems."/home" =
    {
      device = "/dev/disk/by-uuid/adaad601-f79c-4342-ba3a-9eab53ec4cd1";
      fsType = "btrfs";
      options = [ "subvol=@home" "compress=zstd" ];
    };

  fileSystems."/nix" =
    {
      device = "/dev/disk/by-uuid/adaad601-f79c-4342-ba3a-9eab53ec4cd1";
      fsType = "btrfs";
      options = [ "subvol=@nix" "compress=zstd" "noatime" ];
    };

  fileSystems."/swap" =
    {
      device = "/dev/disk/by-uuid/adaad601-f79c-4342-ba3a-9eab53ec4cd1";
      fsType = "btrfs";
      options = [ "subvol=@swap" "noatime" ];
    };

  fileSystems."/mnt/Data" = {
    device = "/dev/disk/by-uuid/239db4ac-762d-4d76-8297-ccd37bcdfd8b";
    fsType = "ext4";
    options = [ "users" "exec" "nofail" "noauto" "x-systemd.automount" ];
  };
  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/0559-4C2D";
      fsType = "vfat";
      options = [ "fmask=0022" "dmask=0022" ];
    };
  # Disk swapfile on @swap is unused; zram is the only swap.
  # After switch: `swapoff /swap/swapfile && rm /swap/swapfile` to reclaim 64G.
  swapDevices = [ ];
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };
  # BTRFS Stuff
  services.btrfs.autoScrub.enable = true;
  services.snapper = {
    persistentTimer = true;
    snapshotRootOnBoot = true;
    configs =
      let
        defaultSettings = {
          TIMELINE_CREATE = true;
          TIMELINE_CLEANUP = true;
          TIMELINE_LIMIT_HOURLY = "10";
          TIMELINE_LIMIT_DAILY = "7";
          TIMELINE_LIMIT_WEEKLY = "0";
          TIMELINE_LIMIT_MONTHLY = "0";
          TIMELINE_LIMIT_YEARLY = "0";
          BACKGROUND_COMPARISON = "yes";
          NUMBER_CLEANUP = "yes";
          NUMBER_MIN_AGE = "1800";
          NUMBER_LIMIT = "10";
          NUMBER_LIMIT_IMPORTANT = "10";
          EMPTY_PRE_POST_CLEANUP = "yes";
          EMPTY_PRE_POST_MIN_AGE = "1800";
        };
      in
      {
        root = defaultSettings // {
          SUBVOLUME = "/";
        };
        home = defaultSettings // {
          SUBVOLUME = "/home";
        };
      };
  };
  environment.systemPackages = [
    pkgs.snapper
    pkgs.snapper-gui
  ];
}
