{ config, skygUtils, skyg-secrets, ... }:
let
  version = "v3";
  app = config.skyg.internalNetworkingMap.apps.immich;
  envVars = {
    REDIS_PORT = "6379";
    REDIS_HOSTNAME = "redis";
    DB_HOSTNAME = "database";

    DB_USERNAME = "immich";
    POSTGRES_USER = "immich";
    POSTGRES_DB = "immich";
    DB_DATABASE_NAME = "immich";

    IMMICH_MACHINE_LEARNING_URL = "http://${config.skyg.internalNetworkingMap.apps.immich-ml.ip}:3003";
  };
  nfsVolume = skygUtils.container-services.nfsVols.tnas1;
in
{
  age.secrets.immich-shared.file = skyg-secrets.immich-shared;

  skyg.nixos.common.container-services.immich = {
    enable = true;
    autoUpdate.enable = true;
    networks = {
      main = { driver = "bridge"; };
      lan = config.skyg.nixos.common.containers.networks.ipvlanLab.compose;
    };
    volumes = {
      family-storage = nfsVolume "/mnt/EightTerra/FamilyStorage";
    };
    services.immich-server = {
      image = "ghcr.io/immich-app/immich-server:${version}";
      environmentFiles = [ config.age.secrets.immich-shared.path ];
      environment = envVars;
      deploy.resources.limits = {
        cpus = "4";
        memory = "8G";
      };
      networks = {
        lan.ipv4_address = app.ip;
        main = { };
      };
      volumes = [
        "/data/fourTerra/immich-upload:/usr/src/app/upload"
        "family-storage:/family-storage"
      ];
      extraConfig.depends_on = {
        database.condition = "service_healthy";
        redis.condition = "service_healthy";
      };
      restart = "always";
    };
    services.redis = {
      image = "docker.io/valkey/valkey:9@sha256:c123e3715db63d06d4ad6964884037aa0d5d4d703939b9929954112889708e1d";
      networks.main = { };
      healthcheck = {
        test = [ "CMD-SHELL" "redis-cli ping || exit 1" ];
        interval = "30s";
        timeout = "5s";
        retries = 5;
        start_period = "10s";
      };
      restart = "always";
    };
    services.database = {
      image = "ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0@sha256:bcf63357191b76a916ae5eb93464d65c07511da41e3bf7a8416db519b40b1c23";
      environmentFiles = [ config.age.secrets.immich-shared.path ];
      environment.POSTGRES_INITDB_ARGS = "--data-checksums";
      networks.main = { };
      volumes = [ "/data/fourTerra/immich-db:/var/lib/postgresql/data" ];
      healthcheck = {
        test = [ "CMD-SHELL" ''pg_isready --dbname="$$POSTGRES_DB" --username="$$POSTGRES_USER" || exit 1'' ];
        interval = "5m";
        timeout = "10s";
        retries = 5;
        start_period = "5m";
        start_interval = "30s";
      };
      restart = "always";
    };
  };
}
