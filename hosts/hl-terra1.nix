{ user }:
{ pkgs, lib, config, ... }: {
  imports = [ ./hl-terra1.hardware-configuration.nix ];
  # firmware updater
  services.fwupd.enable = true;
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  homelab.hardware.fan2go.enable = true;
}

