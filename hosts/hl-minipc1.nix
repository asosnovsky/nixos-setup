{ config, ... }:
let
  ports = {
    audiobookshelf = 8000;
    nixServe = 5000;
    dockerRegistry = 5001;
    postgresIU = 7491;
    ssh = 22;
    iu = 1947;
  };
  gitea = {
    user = "gitea";
    group = "gitea";
    stateDir = "/var/lib/sosnovsky/gitea";
    sshPort = 2222;
    httpPort = 3000;
  };
  openPorts = [
    ports.nixServe
    ports.dockerRegistry
    ports.audiobookshelf
    gitea.sshPort
    gitea.httpPort
    ports.postgresIU
    ports.ssh
    ports.iu
  ];
  # Buzz stack
  buzz = {
    domain = "buzz.lab.internal";
    port = 3000;
    ip = "10.0.101.3";
    bucket = "buzz-media";
  };
  # NFS-backed volume on tnas1 (repo pattern: compose volume with nfs driver_opts).
  # The server must be in `device` (the local driver uses it as the mount source);
  # `o = addr=...` alone is not honoured here.
  nfsVolume = subpath: {
    driver_opts = {
      type = "nfs";
      o = "rw,nfsvers=4.0,nolock,hard,noatime";
      device = "tnas1.lab.internal:/mnt/SmallG/buzz/${subpath}";
    };
  };
in
{
  skyg.user.enable = true;
  skyg.nixos.common.ssh-server.enable = true;
  skyg.server.dns.routing = {
    enable = false;
    openFirewall = true;
    addressesSecretName = "dns-addresses.conf";
  };
  skyg.nixos.common.containers.runtime = "podman";
  skyg.nixos.common.containers.openMetricsPort = true;

  # One shared macvlan network, created once at boot.
  skyg.nixos.common.containers.networks.lab = {
    driver = "macvlan";
    driverOpts.parent = "eno1";
    subnet = "10.0.0.0/16";
    gateway = "10.0.0.1";
    ipRange = "10.0.101.16/28";
  };
  skyg.server.admin.enable = true;
  skyg.server.exporters.enable = true;
  skyg.nixos.server.k3s.enable = false;
  skyg.networkDrives = {
    enable = true;
  };
  services.tailscale.enable = true;
  services.tailscale.disableTaildrop = true;
  services.tailscale.useRoutingFeatures = "both";
  services.tailscale.openFirewall = true;

  # # Nix Stores
  services.nix-serve = {
    enable = true;
    secretKeyFile = "/home/ari/cache-keys/minipc1.lab.internal.private";
    port = ports.nixServe;
  };
  # firmware updater
  services.fwupd.enable = true;
  # # Services
  skyg.nixos.server.services = {
    audiobookshelf = {
      enable = false;
      host = "0.0.0.0";
      openFirewall = true;
      port = ports.audiobookshelf;
      configDir = "/mnt/Data/audiobookshelf/config";
      metadataDir = "/mnt/Data/audiobookshelf/metadata";
    };
  };
  services.dockerRegistry = {
    enable = true;
    storagePath = "/mnt/Data/docker-registry";
    port = ports.dockerRegistry;
    openFirewall = true;
    listenAddress = "0.0.0.0";
    enableDelete = true;
  };
  services.gitea = {
    enable = true;
    appName = "Sosnovsky gitea";
    stateDir = gitea.stateDir;
    user = gitea.user;
    group = gitea.group;
    settings = {
      server = {
        SSH_USER = gitea.user;
        DOMAIN = "minipc1.lab.internal";
        HTTP_PORT = gitea.httpPort;
        SSH_PORT = gitea.sshPort;
        DISABLE_SSH = false;
      };
      service = {
        DISABLE_REGISTRATION = true;
      };
    };
  };

  skyg.nixos.common.container-services.iu = {
    services = {
      db = {
        image = "postgres:18";
        ports = [
          "${toString ports.postgresIU}:5432"
        ];
        volumes = [
          "/var/lib/iu-postgres:/var/lib/postgresql/data"
        ];
        environmentFiles = [ config.age.secrets.iu-project.path ];
        networks = [ "main" ];
      };
      iu = {
        image = "minipc1.lab.internal:5001/iu:2026.07.12-ac2c604";
        ports = [
          "${toString ports.iu}:1947"
        ];
        # Explicit command matches the Containerfile ENTRYPOINT + CMD
        command = [
          "-config"
          "/app/config.toml"
          "-mode"
          "worker+webapp"
        ];
        volumes = [
        ];
        environmentFiles = [
          config.age.secrets.iu-project.path
        ];
        networks = [
          "main"
        ];
        dependsOn = [ "db" ];
        files = {
          "/app/config.toml" = ''
            [web]
            host = "0.0.0.0"
            port = 1947

            [features]
            publish_alt_translations = true
            enable_favourite_marking = true

            [database]
            driver = "postgres"
            dsn = "postgres://postgres@db:5432/iu?sslmode=disable"
            password_env = "POSTGRES_PASSWORD"

            [worker]
            poll_interval_seconds = 1
            job_timeout_seconds = 1200

            [worker.job.ingest]
            enabled = true
            interval_seconds = 21600

            [worker.job.classify_scan]
            enabled = true

            [worker.job.classify]
            enabled = true

            [worker.queue.translate]
            enabled = true

            [worker.queue.rewrite]
            enabled = true

            [worker.queue.term_remap]
            enabled = true

            [worker.queue.reason_backfill]
            enabled = true

            [worker.queue.scan]
            enabled = true
            interval_seconds = 21600

            [data-science.ollama]
            base_url = "http://fwdesk.lab.internal"
            port = 11434
            timeout_seconds = 120

            [data-science.ollama.models]
            rewrite_heb = "aya-expanse"
            rewrite_ru = "aya-expanse"
            rewrite_en = "aya-expanse"

            [data-science.libretranslate]
            endpoint = "http://fwdesk.lab.internal:5000/translate"
            timeout_seconds = 120

            [data-science.classifier]
            model_path = "data/classifier.json"

            [data-science.grok_models.models]
            rewrite_heb = "grok-4.3"
            rewrite_en = "grok-4.3"
            rewrite_ru = "grok-4.3"
          '';
        };
      };
    };
  };

  # Buzz — relay + postgres + redis + garage (S3). Reachable at
  # http://buzz.lab.internal:3000 on its own macvlan IP (10.0.101.3).
  # Data lives on tnas1 via NFS-backed compose volumes (/mnt/SmallG/buzz).
  age.secrets.buzz-env.file = ../secrets/buzz-env.age;
  skyg.nixos.common.container-services.buzz = {
    enable = true;
    autoUpdate.enable = true;
    # Image pulls on first start / after a tag moves can exceed the 120s default.
    timeoutStartSec = 600;

    networks = {
      internal = { driver = "bridge"; };
      # Shared macvlan network created by skyg.nixos.common.containers.networks.lab.
      lan = config.skyg.nixos.common.containers.networks.lab.compose;
    };

    volumes = {
      buzz-postgres = nfsVolume "postgres";
      buzz-redis = nfsVolume "redis";
      buzz-garage = nfsVolume "garage";
      buzz-git = nfsVolume "git";
    };

    services = {
      relay = {
        image = "ghcr.io/block/buzz:main";
        dependsOn = [ "postgres" "redis" "garage" ];
        networks = {
          internal = { };
          lan = { ipv4_address = buzz.ip; };
        };
        environmentFiles = [ config.age.secrets.buzz-env.path ];
        environment = {
          BUZZ_BIND_ADDR = "0.0.0.0:${toString buzz.port}";
          BUZZ_HEALTH_PORT = "8080";
          BUZZ_METRICS_PORT = "9102";
          RELAY_URL = "ws://${buzz.domain}:${toString buzz.port}";
          BUZZ_MEDIA_BASE_URL = "http://${buzz.domain}:${toString buzz.port}/media";
          BUZZ_MEDIA_SERVER_DOMAIN = "${buzz.domain}:${toString buzz.port}";
          BUZZ_CORS_ORIGINS = "http://${buzz.domain}:${toString buzz.port}";
          BUZZ_S3_ENDPOINT = "http://garage:3900";
          BUZZ_S3_REGION = "garage";
          BUZZ_S3_ADDRESSING_STYLE = "path";
          BUZZ_S3_BUCKET = buzz.bucket;
          BUZZ_GIT_REPO_PATH = "/data/git";
          BUZZ_AUTO_MIGRATE = "true";
          BUZZ_GIT_CONFORMANCE_PROBE = "true";
          RUST_LOG = "buzz_relay=info,buzz_db=info,buzz_auth=info,buzz_pubsub=info,tower_http=info";
        };
        volumes = [ "buzz-git:/data/git" ];
        healthcheck = {
          test = [
            "CMD-SHELL"
            "bash -ec 'exec 3<>/dev/tcp/127.0.0.1/8080; printf \"GET /_readiness HTTP/1.1\\r\\nHost: 127.0.0.1\\r\\nConnection: close\\r\\n\\r\\n\" >&3; grep -q \"200 OK\" <&3'"
          ];
          interval = "10s";
          timeout = "3s";
          retries = 12;
          start_period = "30s";
        };
      };

      postgres = {
        image = "postgres:17-alpine";
        networks = [ "internal" ];
        environmentFiles = [ config.age.secrets.buzz-env.path ];
        environment = {
          POSTGRES_DB = "buzz";
          POSTGRES_USER = "buzz";
        };
        volumes = [ "buzz-postgres:/var/lib/postgresql/data" ];
        healthcheck = {
          test = [ "CMD-SHELL" "pg_isready -U buzz -d buzz" ];
          interval = "5s";
          timeout = "5s";
          retries = 12;
          start_period = "10s";
        };
      };

      redis = {
        image = "redis:7-alpine";
        networks = [ "internal" ];
        environmentFiles = [ config.age.secrets.buzz-env.path ];
        volumes = [ "buzz-redis:/data" ];
        files."/usr/local/bin/redis-entrypoint.sh" = ''
          #!/bin/sh
          set -eu
          exec redis-server --appendonly yes --requirepass "$REDIS_PASSWORD"
        '';
        command = [ "sh" "/usr/local/bin/redis-entrypoint.sh" ];
      };

      garage = {
        image = "dxflrs/garage:v2.4.1";
        networks = [ "internal" ];
        environmentFiles = [ config.age.secrets.buzz-env.path ];
        environment.GARAGE_DEFAULT_BUCKET = buzz.bucket;
        volumes = [ "buzz-garage:/var/lib/garage" ];
        command = [ "/garage" "server" "--single-node" "--default-bucket" ];
        files."/etc/garage.toml" = ''
          metadata_dir = "/var/lib/garage/meta"
          data_dir = "/var/lib/garage/data"
          db_engine = "sqlite"

          replication_factor = 1

          rpc_bind_addr = "[::]:3901"
          rpc_public_addr = "127.0.0.1:3901"

          [s3_api]
          s3_region = "garage"
          api_bind_addr = "[::]:3900"
          root_domain = ".s3.garage.localhost"
        '';
        healthcheck = {
          test = [ "CMD" "/garage" "status" ];
          interval = "30s";
          timeout = "10s";
          retries = 5;
          start_period = "20s";
        };
      };
    };
  };

  # Certbot TLS service
  skyg.server.dns.certbot = {
    enable = false;
    email = "admin@skyg.ca";
    publicDomains = [
      ".*skyg.ca"
      ".*home.sosnovsky.ca"
    ];
  };

  # Firewall
  networking.firewall.allowedUDPPorts = openPorts;
  networking.firewall.allowedTCPPorts = openPorts;
}
