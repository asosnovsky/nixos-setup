{ user }:
{ ... }:
{
  imports = [ ./hl-minipc2.hardware-configuration.nix ];
  skyg.user.enable = true;
  skyg.nixos.common.ssh-server.enable = true;
  skyg.nixos.common.containers.openMetricsPort = true;
  skyg.server.exporters.enable = true;
  skyg.networkDrives = {
    enable = true;
  };

  # firmware updater
  services.fwupd.enable = true;
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # Disable firewall
  networking.firewall.enable = false;
  # Special udev rule for google's coral tpu
  skyg.nixos.server.udevrules.coraltpu.enable = true;

  # Services
  skyg.nixos.server.services = {
    scrypted.enable = true;
    dockge = {
      enable = true;
      openFirewall = true;
      stacksDir = "/mnt/terra1/Data/apps/arrs/dockge/stacks";
      dataDir = "/mnt/terra1/Data/apps/arrs/dockge/data";
    };
  };
}

