{ pkgs, config, ... }:
let
  user = {
    name = "ari";
    fullName = "Ari Sosnovsky";
    email = "ariel@sosnovsky.ca";
  };
in
{
  imports =
    [
      /etc/nixos/cachix.nix
      <nixos-hardware/framework/13-inch/7040-amd>
      (import /home/ari/nixos-setup/main.nix {
        enableFingerPrint = true;
        hostName = "fwbook";
        user = user;
      })
      /home/ari/nixos-setup/modules/optional/amd-packages.nix
      /home/ari/nixos-setup/modules/optional/gnome.nix
      (import /home/ari/nixos-setup/modules/optional/hyprland.nix {
        user = user;
      })
    ];
  hardware.framework.amd-7040.preventWakeOnAC = true;
  services.fwupd.enable = true;
  fileSystems."/mnt/Data" = {
    device = "/dev/sda1";
    fsType = "ext4";
    options = [
      "users"
      "nofail"
    ];
  };
}
