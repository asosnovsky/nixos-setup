{ user
, dataDir ? "/mnt/Data"
}:
{ ... }:
{
  imports =
    [
      ./fwbook.hardware-configuration.nix
    ];
  hardware.framework.amd-7040.preventWakeOnAC = true;
  services.fwupd.enable = true;
  fileSystems."${dataDir}" = {
    device = "/dev/sda1";
    fsType = "ext4";
    options = [
      "users"
      "nofail"
    ];
  };
}
