{ pkgs, config, ... }:
{
  skyg.user.enable = true;
  skyg.nixos.common.ssh-server.enable = true;
  skyg.server.dns.routing = {
    enable = false;
    openFirewall = true;
    addressesSecretName = "dns-addresses.conf";
  };
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

  # NFS Docker volumes for dockge
  # system.activationScripts.dockge-create-volume-stacks = {
  #   text = ''
  #     ${pkgs.docker}/bin/docker volume create \
  #       --driver local \
  #       --opt type=nfs \
  #       --opt o=addr=terra1.lab.internal,rw,nfsvers=4.0,nolock,hard,noatime \
  #       --opt device=:/mnt/Data/apps/arrs/dockge/stacks \
  #       dockge-stacks
  #   '';
  #   deps = [ ];
  # };
  # system.activationScripts.dockge-create-volume-data = {
  #   text = ''
  #     ${pkgs.docker}/bin/docker volume create \
  #       --driver local \
  #       --opt type=nfs \
  #       --opt o=addr=terra1.lab.internal,rw,nfsvers=4.0,nolock,hard,noatime \
  #       --opt device=:/mnt/Data/apps/arrs/dockge/data \
  #       dockge-data
  #   '';
  #   deps = [ ];
  # };
  # system.activationScripts.scrypted-create-volume-nvr = {
  #   text = ''
  #     ${pkgs.docker}/bin/docker volume create \
  #       --driver local \
  #       --opt type=nfs \
  #       --opt o=addr=tnas1.lab.internal,rw,nfsvers=4.0,nolock,hard,noatime \
  #       --opt device=:/mnt/OneT/NVR \
  #       scrypted-nvr
  #   '';
  #   deps = [ ];
  # };

  # Dockge container service group
  skyg.nixos.common.container-services.dockge = {
    services.dockge = {
      image = "louislam/dockge:1";
      ports = [ "5001:5001" ];
      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock"
        "dockge-data:/app/data"
        "dockge-stacks:/opt/stacks"
      ];
      environment.DOCKGE_STACKS_DIR = "/opt/stacks";
    };
    extraConfig.volumes = {
      dockge-data = {
        driver = "local";
        driver_opts = {
          type = "nfs";
          o = "addr=terra1.lab.internal,rw,nfsvers=4.0,nolock,hard,noatime";
          device = ":/mnt/Data/apps/arrs/dockge/data";
        };
      };
      dockge-stacks = {
        driver = "local";
        driver_opts = {
          type = "nfs";
          o = "addr=terra1.lab.internal,rw,nfsvers=4.0,nolock,hard,noatime";
          device = ":/mnt/Data/apps/arrs/dockge/stacks";
        };
      };
    };
  };

  # Scrypted container service group
  skyg.nixos.common.container-services.scrypted = {
    services.scrypted = {
      image = "ghcr.io/koush/scrypted";
      volumes = [
        "/var/run/dbus:/var/run/dbus"
        "/var/run/avahi-daemon/socket:/var/run/avahi-daemon/socket"
        "/opt/homelab/scrypted/db:/server/volume"
        "scrypted-nvr:/nvr"
      ];
      environment.SCRYPTED_NVR_VOLUME = "/nvr";
      extraConfig = {
        network_mode = "host";
        networks = [ ];
      };
    };
    extraConfig.volumes = {
      scrypted-nvr = {
        driver = "local";
        driver_opts = {
          type = "nfs";
          o = "addr=tnas1.lab.internal,rw,nfsvers=4.0,nolock,hard,noatime";
          device = ":/mnt/OneT/NVR";
        };
      };
    };
  };

  # Scrypted backup & autoupdate timers
  skyg.server.timers = {
    scrypted-backups = {
      OnCalendar = "daily";
      wantedBy = [ "homelab-terra1-Data-apps.mount" ];
      script = ''
        set -eu
        ${pkgs.rsync}/bin/rsync -avpzP --delete /opt/homelab/scrypted /homelab/terra1/Data/apps/
      '';
    };
    scrypted-autoupdate = {
      OnCalendar = "weekly";
      script = ''
        set -eu
        ${pkgs.docker}/bin/docker pull ghcr.io/koush/scrypted
        systemctl restart container-services-scrypted.service
      '';
    };
  };
}
