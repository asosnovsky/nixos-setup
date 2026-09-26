{ config, ... }:
let
  nfsVolume = exportPath: {
    driver_opts = {
      type = "nfs";
      o = "addr=tnas1.lab.internal,rw,nfsvers=4.0,nolock,hard,noatime";
      device = ":${exportPath}";
    };
  };
  app = config.skyg.internalNetworkingMap.apps.buzz;
  buzz = {
    domain = app.effectiveDns;
    publicDomain = app.aliasDns;
    port = 3000;
    ip = app.ip;
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
in
{
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
