{ config, pkgs, ... }:
let
  nfsVolume = exportPath: {
    driver_opts = {
      type = "nfs";
      o = "addr=tnas1.lab.internal,rw,nfsvers=4.0,nolock,hard,noatime";
      device = ":${exportPath}";
    };
  };
  audiobookshelf = {
    domain = "audiobooks.app.internal";
    ip = "10.0.101.4";
    port = 80;
    image = "ghcr.io/advplyr/audiobookshelf:latest";
    dataDir = "/mnt/Data/audiobookshelf";
  };
  buzz = {
    domain = "buzz.app.internal";
    publicDomain = "buzz.home.sosnovsky.ca";
    port = 3000;
    ip = "10.0.101.3";
    bucket = "buzz-media";
    images = {
      relay = "ghcr.io/block/buzz:main";
      caddy = "caddy:2-alpine";
      posgres = "postgres:17-alpine";
      redis = "redis:7-alpine";
      minio = "quay.io/minio/minio:RELEASE.2025-09-07T16-13-09Z@sha256:14cea493d9a34af32f524e538b8346cf79f3321eff8e708c1e2960462bd8936e";
      mc = "quay.io/minio/mc:RELEASE.2025-08-13T08-35-41Z@sha256:a7fe349ef4bd8521fb8497f55c6042871b2ae640607cf99d9bede5e9bdf11727";
    };
  };
  ports = {
    postgresIU = 7491;
    iu = 1947;
  };
in
{
  skyg.nixos.common.container-services.audiobookshelf = {
    enable = true;
    autoUpdate.enable = true;
    networks.lan = config.skyg.nixos.common.containers.networks.ipvlanLab.compose;
    volumes.books = nfsVolume "/mnt/EightTerra/DownloadedTorrents/books";
    services.audiobookshelf = {
      image = audiobookshelf.image;
      networks.lan.ipv4_address = audiobookshelf.ip;
      dns.names = [ audiobookshelf.domain ];
      environment.PORT = toString audiobookshelf.port;
      volumes = [
        "${audiobookshelf.dataDir}/config:/config"
        "${audiobookshelf.dataDir}/metadata:/metadata"
        "books:/audiobooks"
        "${audiobookshelf.dataDir}/podcasts:/podcasts"
      ];
    };
  };

  skyg.nixos.common.container-services.iu = {
    services = {
      db = {
        image = "postgres:18";
        ports = [ "${toString ports.postgresIU}:5432" ];
        volumes = [ "/var/lib/iu-postgres:/var/lib/postgresql/data" ];
        environmentFiles = [ config.age.secrets.iu-project.path ];
        networks = [ "main" ];
      };
      iu = {
        image = "minipc1.lab.internal:5001/iu:2026.07.12-ac2c604";
        ports = [ "${toString ports.iu}:1947" ];
        command = [ "-config" "/app/config.toml" "-mode" "worker+webapp" ];
        environmentFiles = [ config.age.secrets.iu-project.path ];
        networks = [ "main" ];
        dependsOn = [ "db" ];
        files."/app/config.toml" = ''
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

  skyg.nixos.common.container-services.buzz = {
    enable = true;
    autoUpdate.enable = true;
    timeoutStartSec = 600;
    networks = {
      internal = { driver = "bridge"; };
      lan = config.skyg.nixos.common.containers.networks.ipvlanLab.compose;
    };
    volumes = {
      buzz-postgres = nfsVolume "/mnt/SmallG/buzz/postgres";
      buzz-redis = nfsVolume "/mnt/SmallG/buzz/redis";
      s3 = nfsVolume "/mnt/SmallG/buzz/s3";
      buzz-git = nfsVolume "/mnt/SmallG/buzz/git";
    };
    services = {
      relay = {
        image = buzz.images.relay;
        extraConfig.depends_on = {
          postgres.condition = "service_healthy";
          redis.condition = "service_healthy";
          minio.condition = "service_healthy";
          minio-init.condition = "service_completed_successfully";
        };
        networks = [ "internal" ];
        environmentFiles = [ config.age.secrets.buzz-env.path ];
        environment = {
          BUZZ_BIND_ADDR = "0.0.0.0:${toString buzz.port}";
          BUZZ_HEALTH_PORT = "8080";
          BUZZ_METRICS_PORT = "9102";
          RELAY_URL = "wss://${buzz.publicDomain}";
          BUZZ_MEDIA_BASE_URL = "https://${buzz.publicDomain}/media";
          BUZZ_MEDIA_SERVER_DOMAIN = buzz.publicDomain;
          BUZZ_CORS_ORIGINS = "https://${buzz.publicDomain}";
          BUZZ_S3_ENDPOINT = "http://minio:9000";
          BUZZ_S3_REGION = "us-east-1";
          BUZZ_S3_ADDRESSING_STYLE = "path";
          BUZZ_S3_BUCKET = buzz.bucket;
          BUZZ_GIT_REPO_PATH = "/data/git";
          BUZZ_AUTO_MIGRATE = "true";
          BUZZ_GIT_CONFORMANCE_PROBE = "true";
          RUST_LOG = "buzz_relay=info,buzz_db=info,buzz_auth=info,buzz_pubsub=info,tower_http=info";
        };
        volumes = [ "buzz-git:/data/git" ];
        healthcheck = {
          test = [ "CMD-SHELL" "bash -ec 'exec 3<>/dev/tcp/127.0.0.1/8080; printf \"GET /_readiness HTTP/1.1\\r\\nHost: 127.0.0.1\\r\\nConnection: close\\r\\n\\r\\n\" >&3; grep -q \"200 OK\" <&3'" ];
          interval = "10s";
          timeout = "3s";
          retries = 12;
          start_period = "30s";
        };
      };
      caddy = {
        image = buzz.images.caddy;
        extraConfig.depends_on.relay.condition = "service_healthy";
        networks = {
          internal = { };
          lan = { ipv4_address = buzz.ip; };
        };
        dns.names = [ buzz.domain buzz.publicDomain ];
        files."/etc/caddy/Caddyfile" = ''
          ${buzz.publicDomain} {
            tls /etc/caddy/tls/fullchain.pem /etc/caddy/tls/key.pem
            encode zstd gzip
            reverse_proxy relay:${toString buzz.port}
          }
          http://${buzz.domain} {
            redir https://${buzz.publicDomain}{uri} permanent
          }
          :${toString buzz.port} {
            reverse_proxy relay:${toString buzz.port}
          }
          :8080 {
            reverse_proxy relay:8080
          }
          :9102 {
            reverse_proxy relay:9102
          }
        '';
        volumes = [
          "/var/lib/acme/${buzz.publicDomain}/fullchain.pem:/etc/caddy/tls/fullchain.pem:ro"
          "/var/lib/acme/${buzz.publicDomain}/key.pem:/etc/caddy/tls/key.pem:ro"
        ];
      };
      postgres = {
        image = buzz.images.posgres;
        networks = [ "internal" ];
        environmentFiles = [ config.age.secrets.buzz-env.path ];
        environment = {
          POSTGRES_DB = "buzz";
          POSTGRES_USER = "buzz";
          PGDATA = "/var/lib/postgresql/data/pgdata";
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
        image = buzz.images.redis;
        networks = [ "internal" ];
        environmentFiles = [ config.age.secrets.buzz-env.path ];
        volumes = [ "buzz-redis:/data" ];
        files."/usr/local/bin/redis-entrypoint.sh" = ''
          #!/bin/sh
          set -eu
          exec redis-server --appendonly yes --requirepass "$REDIS_PASSWORD"
        '';
        command = [ "sh" "/usr/local/bin/redis-entrypoint.sh" ];
        healthcheck = {
          test = [ "CMD-SHELL" ''redis-cli -a "$''${REDIS_PASSWORD}" ping | grep -q PONG'' ];
          interval = "5s";
          timeout = "3s";
          retries = 12;
          start_period = "5s";
        };
      };
      minio = {
        image = buzz.images.minio;
        networks = [ "internal" ];
        environmentFiles = [ config.age.secrets.buzz-env.path ];
        volumes = [ "s3:/data" ];
        command = [ "server" "/data" "--console-address" ":9001" ];
        healthcheck = {
          test = [ "CMD" "curl" "-f" "http://127.0.0.1:9000/minio/health/live" ];
          interval = "5s";
          timeout = "5s";
          retries = 12;
          start_period = "10s";
        };
      };
      minio-init = {
        image = buzz.images.mc;
        networks = [ "internal" ];
        environmentFiles = [ config.age.secrets.buzz-env.path ];
        environment.BUZZ_S3_BUCKET = buzz.bucket;
        files."/usr/local/bin/minio-init.sh" = ''
          #!/bin/sh
          set -eu
          echo "setting alias"
          mc alias set local http://minio:9000 "$BUZZ_S3_ACCESS_KEY" "$BUZZ_S3_SECRET_KEY"
          echo "creating bucket"
          mc mb -p local/$BUZZ_S3_BUCKET
          echo "setting bucket permissions"
          mc anonymous set none local/$BUZZ_S3_BUCKET
        '';
        extraConfig = {
          entrypoint = [ "/bin/sh" "/usr/local/bin/minio-init.sh" ];
          depends_on.minio.condition = "service_healthy";
        };
        restart = "no";
      };
    };
  };
}
