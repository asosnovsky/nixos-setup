{ config, lib, pkgs, nbot, skyg-secrets, ... }:
let
  ports = { cluster = 7946; };
  homes = "/data/nbot";
  secrets = [ "nbot-slack" "nbot-goose" "nbot-cluster" ];
  settings = {
    # The system each container boots; updated on every rebuild.
    system = "${nbot.packages.${pkgs.stdenv.hostPlatform.system}.agent}";
    machines_dir = "/var/lib/machines";
    state_dir = "/var/lib/nbot";
    agent_cwd = "/root";

    idle_timeout = "6h";
    max_idle_timeout = "0s";
    allow_indefinite = true;
    boot_timeout = "2m";

    # Goose settings sent to every container (also on fws1).
    # Values come from the nbot-goose secret.
    agent_env = {
      GOOSE_PROVIDER = "$GOOSE_PROVIDER";
      GOOSE_MODEL = "$GOOSE_MODEL";
      OPENROUTER_API_KEY = "$OPENROUTER_API_KEY";
      CLAUDE_CODE_OAUTH_TOKEN = "$CLAUDE_CODE_OAUTH_TOKEN";
      COMMAND_CODE_API_KEY = "$COMMAND_CODE_API_KEY";
    };

    model_providers = [
      {
        id = "claude-acp";
        name = "Claude ACP (Ari Credentials)";
        key_env = "CLAUDE_CODE_OAUTH_TOKEN";
        models = [ "default" "sonnet" "haiku" ];
        users = [ "U0CBGSS4U6A" ];
      }
      {
        id = "custom_commandcode";
        name = "Command Code";
        key_env = "COMMAND_CODE_API_KEY";
        models = [ "deepseek/deepseek-v4-flash" ];
      }
    ];

    container = { memory_mb = 4096; cpus = 1.0; };
    max_container = { memory_mb = 8192; cpus = 2.0; };
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
      managers = [ "U0CBGSS4U6A" ];
      default.U0CBGSS4U6A = [ "all" ];
    };
  };
in
{
  age.secrets = lib.genAttrs secrets (name: {
    file = skyg-secrets.${name};
    owner = "root";
    mode = "0400";
  });

  # nbot flake input; options and docs in its repo.
  services.nbot = {
    enable = true;
    mode = "master";
    clusterPort = ports.cluster;
    configFile = (pkgs.formats.toml { }).generate "nbot.toml" settings;
  };

  # The module takes one env file; these add to it.
  systemd.services.nbot.serviceConfig.EnvironmentFile =
    map (name: config.age.secrets.${name}.path) secrets;

  # Container links belong to systemd-networkd.
  networking.networkmanager.unmanaged = [ "interface-name:ve-*" ];
  networking.dhcpcd.denyInterfaces = [ "ve-*" ];

  systemd.tmpfiles.rules = [ "d ${homes} 0700 root root -" ];
}
