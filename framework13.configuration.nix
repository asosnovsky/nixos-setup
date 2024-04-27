{ pkgs, config, ... }:
let
  user = {
    name = "ari";
    fullName = "Ari Sosnovsky";
    email = "ariel@sosnovsky.ca";
  };
  dataDir = "/mnt/Data";
in
{
  imports =
    [
      /etc/nixos/cachix.nix
      /etc/nixos/hardware-configuration.nix
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
  fileSystems."${dataDir}" = {
    device = "/dev/sda1";
    fsType = "ext4";
    options = [
      "users"
      "nofail"
    ];
  };
  # home-manager.users.${user.name}.zsh.extraEnv = ''
  #   export KUBECONFIG=${dataDir}/local/kube/config.yml
  # '';
}
