{ config, lib, pkgs, slackerbot, skyg-secrets, ... }:
let
  ports = { cluster = 7946; };
  homes = "/data/slackerbot";
  secrets = [ "slackerbot-slack" "slackerbot-goose" "slackerbot-cluster" ];
  settings = {
    # The system each container boots; updated on every rebuild.
    system = "${slackerbot.packages.${pkgs.stdenv.hostPlatform.system}.agent}";
    machines_dir = "/var/lib/machines";
    state_dir = "/var/lib/slackerbot";
    agent_cwd = "/root";

    idle_timeout = "6h";
    max_idle_timeout = "0s";
    allow_indefinite = true;
    boot_timeout = "2m";

    # Goose settings sent to every container (also on fws1).
    # Values come from the slackerbot-goose secret.
    agent_env = {
      GOOSE_PROVIDER = "$GOOSE_PROVIDER";
      GOOSE_MODEL = "$GOOSE_MODEL";
      OPENROUTER_API_KEY = "$OPENROUTER_API_KEY";
    };

    container = { memory_mb = 1024; cpus = 1.0; };
    max_container = { memory_mb = 4096; cpus = 2.0; };
    # Leave room for ollama, ds4, comfyui, hermes and the robots.
    host_reserve = { memory_mb = 32768; cpus = 4.0; };
    storage = { min = "2G"; max = "5G"; limit = "20G"; };
    drives = [{ path = homes; reserve = "40G"; }];

    cluster = {
      secret = "$CLUSTER_SECRET";
      listen = ":${toString ports.cluster}";
    };

    # Only read on first start; after that, manage permissions from Slack.
    permissions = {
      managers = [ "U0CDGSJADMM" ];
      default.U0CDGSJADMM = [ "all" ];
    };
  };
in
{
  age.secrets = lib.genAttrs secrets (name: {
    file = skyg-secrets.${name};
    owner = "root";
    mode = "0400";
  });

  # slackerbot flake input; options and docs in its repo.
  services.slackerbot = {
    enable = true;
    mode = "master";
    clusterPort = ports.cluster;
    configFile = (pkgs.formats.toml { }).generate "slackerbot.toml" settings;
  };
  # The module takes one env file; these add to it.
  systemd.services.slackerbot.serviceConfig.EnvironmentFile =
    map (name: config.age.secrets.${name}.path) secrets;

  # Container links belong to systemd-networkd.
  networking.networkmanager.unmanaged = [ "interface-name:ve-*" ];
  networking.dhcpcd.denyInterfaces = [ "ve-*" ];

  systemd.tmpfiles.rules = [ "d ${homes} 0700 root root -" ];
}
