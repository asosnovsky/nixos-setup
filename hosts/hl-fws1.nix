{ user }:
{ pkgs, ... }:
let
  scriptsFolder = builtins.filterSource (p: t: true) ./scripts/fw1;
in
{
  imports = [ ./hl-fws1.hardware-configuration.nix ];
  skyg.user.enable = true;
  skyg.nixos.common.ssh-server.enable = true;
  skyg.server.admin.enable = true;
  skyg.nixos.server.k3s.enable = true;
  skyg.networkDrives = {
    enable = true;
    options = [
      "x-systemd.automount"
      "auto"
      "nofail"
      "_netdev"
    ];
  };
  # firmware updater
  services.fwupd.enable = true;
  hardware.framework.enableKmod = true;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.tmp.useTmpfs = true;

  # Kernel
  boot.kernelPackages = pkgs.linuxPackages_zen;
}

