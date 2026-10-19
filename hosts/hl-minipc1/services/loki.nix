{ ... }:
let
  ports = {
    loki = 3100;
    grpc = 9096;
  };
  dataDir = "/var/lib/loki";
in
{
  services.loki = {
    enable = true;

    # Single-binary Loki on the filesystem: no object store, no ring.
    configuration = {
      auth_enabled = false;

      server = {
        http_listen_port = ports.loki;
        grpc_listen_port = ports.grpc;
      };

      common = {
        instance_addr = "127.0.0.1";
        path_prefix = dataDir;
        replication_factor = 1;
        ring.kvstore.store = "inmemory";
        storage.filesystem = {
          chunks_directory = "${dataDir}/chunks";
          rules_directory = "${dataDir}/rules";
        };
      };

      schema_config.configs = [
        {
          from = "2026-10-01";
          store = "tsdb";
          object_store = "filesystem";
          schema = "v13";
          index = {
            prefix = "index_";
            period = "24h";
          };
        }
      ];

      # The compactor is what enforces the 24h window below.
      compactor = {
        working_directory = "${dataDir}/compactor";
        retention_enabled = true;
        delete_request_store = "filesystem";
      };

      limits_config = {
        retention_period = "24h";
        reject_old_samples = true;
        reject_old_samples_max_age = "168h";
        # Required for OTLP ingestion; on by default since 3.0.
        allow_structured_metadata = true;
      };

      ruler = {
        storage.type = "local";
        storage.local.directory = "${dataDir}/rules";
      };
    };
  };

  # Loki data lives on tnas1. Prometheus and Grafana stay on local disk, since
  # their databases do not work well on NFS.
  # The export must exist on the NAS and be writable by uid 985 / gid 981.
  # The mount is ordered after network-online so tnas1's name resolves at boot.
  fileSystems.${dataDir} = {
    device = "tnas1.lab.internal:/mnt/SmallG/monitoring/loki";
    fsType = "nfs";
    options = [
      "nfsvers=4.0"
      "hard"
      "noatime"
      "nofail"
      "_netdev"
      "x-systemd.automount"
      "x-systemd.requires=network-online.target"
      "x-systemd.after=network-online.target"
    ];
  };
  systemd.services.loki.unitConfig.RequiresMountsFor = [ dataDir ];

  # NFS ownership is numeric, so pin the ids instead of letting NixOS assign
  # them by name order (a new user sorting before "loki" would shift them).
  users.users.loki.uid = 985;
  users.groups.loki.gid = 981;

  networking.firewall.allowedTCPPorts = [ ports.loki ];
}
