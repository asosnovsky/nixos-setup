{ config, ... }:
let
  ports = {
    postgresIU = 7491;
    iu = 1947;
  };
in
{

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
}
