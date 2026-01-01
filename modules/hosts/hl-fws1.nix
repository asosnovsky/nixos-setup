{ pkgs, ... }:
{
  skyg.user.enable = true;
  skyg.nixos.common.ssh-server.enable = true;
  skyg.nixos.server.k3s.enable = true;
  skyg.server.admin.enable = true;
  skyg.networkDrives = {
    enable = true;
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
