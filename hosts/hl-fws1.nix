{ user }:
{ pkgs, lib, config, ... }: {
  imports = [ ./hl-minipc1.hardware-configuration.nix ];

  # firmware updater
  services.fwupd.enable = true;
  hardware.framework.enableKmod = true;
  homelab.nix.remote-builder.enable = true;

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.tmp.useTmpfs = true;
}

