{ user
, dataDir ? "/mnt/Data"
}:
{ ... }:
{
  imports =
    [
      ./fwbook.hardware-configuration.nix
    ];
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
