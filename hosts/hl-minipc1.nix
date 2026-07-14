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
in
{
  skyg.user.enable = true;
  skyg.nixos.common.ssh-server.enable = true;
  skyg.server.dns.routing = {
    enable = false;
    openFirewall = true;
    addressesSecretName = "dns-addresses.conf";
  };
  skyg.nixos.common.containers.openMetricsPort = true;
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
