{ config, lib, pkgs, skyg-secrets, ... }:
let
  ports = { cluster = 7946; };
  homes = "/data/nbot";
  secrets = [ "nbot-slack" "nbot-goose" "nbot-cluster" ];
  settings = {
    # The system each container boots (nbot's agent + gh); updated on every rebuild.
    system = "${config.skyg.nixos.server.services.nbot-agent.system}";
    machines_dir = "/var/lib/machines";
    state_dir = "/var/lib/nbot";
    agent_cwd = "/root";

    idle_timeout = "6h";
    max_idle_timeout = "0s";
    allow_indefinite = true;
    boot_timeout = "2m";

    summaries = {
      timeout = "10s";
    };

    # Goose settings sent to every container (also on fws1).
    # Values come from the nbot-goose secret.
    agent_env = {
      GOOSE_PROVIDER = "$GOOSE_PROVIDER";
      GOOSE_MODEL = "$GOOSE_MODEL";
      OPENROUTER_API_KEY = "$OPENROUTER_API_KEY";
      CLAUDE_CODE_OAUTH_TOKEN = "$CLAUDE_CODE_OAUTH_TOKEN";
      COMMAND_CODE_API_KEY = "$COMMAND_CODE_API_KEY";
      GH_TOKEN = "$GH_TOKEN";
    };

    model_providers = [
      {
        id = "claude-acp";
        name = "Claude ACP (Ari Credentials)";
        key_env = "CLAUDE_CODE_OAUTH_TOKEN";
        models = [ "default" "sonnet" "haiku" "opus" ];
        users = [ "U0CBGSS4U6A" ];
      }
      {
        id = "claude-oauth";
        name = "Claude OAuth";
        personal = true;
        upstream = "https://api.anthropic.com";
        engine = "claude-code";
        login = "claude";
        models = [ "default" "opus" "sonnet" "haiku" "fable" ];
      }
      # {
      #   id = "codex";
      #   name = "Codex (OpenAI API key)";
      #   personal = true;
      #   upstream = "https://api.openai.com";
      #   engine = "openai";
      #   auth = "bearer";
      #   models = [ "gpt-6.1-codex" "gpt-6.1" ];
      # }
      # {
      #   id       = "xai";
      #   name     = "Grok";
      #   personal = true;
      #   upstream = "https://api.x.ai";
      #   engine   = "openai";
      #   auth     = "bearer";
      #   models   = ["grok-4"];
      # }
      {
        id = "custom_commandcode";
        name = "Command Code";
        key_env = "COMMAND_CODE_API_KEY";
        models = [
          "deepseek/deepseek-v4-flash"
          "minimax/minimax-m3.1-flash"
          "minimaxai/minimax-m3"
          "anthropic/claude-opus-5-5"
          "anthropic/claude-sonnet-5-5"
          "anthropic/claude-haiku-5-5"
          "reflection/beam:free"
          "moonshotai/kimi-k3"
          "moonshotai/kimi-k2.7-code"
          "zai-org/glm-5.3"
          "z-ai/glm-5.3-flash"
          "xai/grok-4.7"
          "openai/gpt-6.1-sol"
        ];
      }
    ];

    container = { memory_mb = 4096; cpus = 1.0; };
    max_container = { memory_mb = 16384; cpus = 4; };
    host_reserve = { memory_mb = 32768; cpus = 4.0; };
    storage = { min = "2G"; max = "5G"; limit = "20G"; };
    drives = [{ path = homes; reserve = "40G"; allow_subdir = true; }];

    cluster = {
      node_secrets = { hl-fws1 = "$HL_FWS1_CLUSTER_SECRET"; };
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
    kvm = true;
    drives = [ homes ];
    stateDir = "/var/lib/nbot";
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
