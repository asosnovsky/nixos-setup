{ config, lib, skyg-secrets, ... }:
let
  apps = config.skyg.internalNetworkingMap.apps;
  robotSecrets = [ "robots-shared" "robots-sibli" ];
  secret = name: config.age.secrets.${name}.path;
  ports = {
    ollama = 11434;
    ds4 = 8000;
    tracker = 1984;
  };
in
{
  age.secrets = lib.genAttrs robotSecrets (name: {
    file = skyg-secrets.${name};
    owner = "root";
    mode = "0400";
  });

  skyg.nixos.server.robotnix = {
    enable = true;
    externalInterface = "enp191s0";

    # Every robot gets this tier. Same holes as the Hermes VM.
    access.shared = {
      internet = "all";
      hostAccess = [
        { port = ports.ollama; }
      ];
      lanAccess = [ ];
    };

    # A Hermes agent in every robot.
    hermes = {
      enable = true;
      environmentFiles = [ (secret "robots-shared") ];
    };

    robots.sibli = {
      id = 2;
      address = apps.sibli.ip;
      cpus = { min = 1; max = 4; };
      memory = { min = "2G"; max = "16G"; };
      disk = { rootSize = "100G"; homeSize = "60G"; };
      seed.configuration = ./robotnix/sibli.nix;
      hermes = {
        name = "Siblix";
        environmentFiles = [ (secret "robots-sibli") ];
        settings.model = {
          provider = "anthropic";
          default = "claude-haiku-5-5";
        };
      };
      allowDocker = true;
      allowTun = true;
      ephemeral = true;
      persist = [
        "/var/lib/tailscale"
        "/var/lib/docker"
      ];
      access = { };
      git.enable = false;
    };
  };
}
