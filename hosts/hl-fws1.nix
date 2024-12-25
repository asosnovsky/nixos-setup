{ user }:
{ pkgs, lib, config, ... }: {
  imports = [ ./hl-fws1.hardware-configuration.nix ];
  skyg.user.enable = true;
  skyg.nixos.common.ssh-server.enable = true;
  skyg.server.admin.enable = true;
  skyg.networkDrives.options = [
    "x-systemd.automount"
    "auto"
  ];

  # firmware updater
  services.fwupd.enable = true;
  hardware.framework.enableKmod = true;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.tmp.useTmpfs = true;
}

