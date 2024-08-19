{ user }:
{ pkgs, lib, config, ... }: {
  imports = [ ./hl-minipc1.hardware-configuration.nix ];
  skyg.user.enabled = true;
  skyg.nixos.common.ssh-server.enabled = true;

  # firmware updater
  services.fwupd.enable = true;
  hardware.framework.enableKmod = true;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.tmp.useTmpfs = true;
}

