{ user }:
{ pkgs
, ...
}:
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

  # Services
  skyg.nixos.server.services = {
    scrypted.enable = true;
    dockge = {
      enable = true;
      openFirewall = true;
      volumes = {
        stacks = {
          nfsServer = "terra1.lab.internal";
          share = "/mnt/Data/apps/arrs/dockge/stacks";
        };
        data = {
          nfsServer = "terra1.lab.internal";
          share = "/mnt/Data/apps/arrs/dockge/data";
        };
      };
    };
  };
}

