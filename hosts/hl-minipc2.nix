{ user }:
{ pkgs, lib, config, ... }: {
  imports = [ ./hl-minipc2.hardware-configuration.nix ];
  # firmware updater
  services.fwupd.enable = true;
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  homelab.nix.remote-builder = true;
  # Special udev rule for google's coral tpu
  homelab.udevrules.coraltpu.enable = true;
}

