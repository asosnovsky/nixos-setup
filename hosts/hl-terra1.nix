{ user }:
{ pkgs, lib, config, ... }:
{
  imports = [ ./hl-terra1.hardware-configuration.nix ];
  skyg.user.enabled = true;
  skyg.ssh-server.enabled = true;
  # firmware updater
  services.fwupd.enable = true;
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
}

