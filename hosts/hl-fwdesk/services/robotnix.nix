{ config, lib, skyg-secrets, ... }:
let
  apps = config.skyg.internalNetworkingMap.apps;
  robotSecrets = [ "robots-shared" "robots-sibli" "robots-genix" ];
  secret = name: config.age.secrets.${name}.path;
  ports = {
    ollama = 11434;
    ds4 = 8000;
    tracker = 1984;
  };
  # A robot's seed: its config plus the files it shares with the others.
  # Each robot gets copies under /etc/nixos/seed (same layout as this repo),
  # so a robot that rebuilds itself (genix) keeps working.
  seedOf = file: {
    root = ../../..;
    configuration = file;
    extraFiles = [
      ./robotnix/common.nix
      ./robotnix/buzz.nix
      ../../../pkgs/buzz-cli
    ];
  };
in
{
  age.secrets = lib.genAttrs robotSecrets (name: {
    file = skyg-secrets.${name};
    owner = "root";
    mode = "0400";
  });

  # robotnix flake input; options and docs in its repo.
  services.robotnix = {
    enable = true;
    externalInterface = "enp191s0";

    # Every robot gets this tier. Same holes as the Hermes VM.
    access.shared = {
      internet = "all";
      hostAccess = [
        { port = ports.ollama; }
      ];
      lanAccess = [
        { address = "10.0.101.3"; port = 443; }
        { address = "10.0.101.3"; port = 3000; }
        { address = "10.0.101.3"; port = 8080; }
        { address = "10.0.101.3"; port = 9102; }
      ];
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
      seed = seedOf ./robotnix/sibli.nix;
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

    # Persistent and self-managing: genix changes and applies its own system
    # (robotnix-apply), pushes its flake to gitea, and pulls it back after a
    # reseed. Add /var/lib/robotnix-git/id_ed25519.pub (inside genix) as a
    # deploy key with write access on ari/genix.
    robots.genix = {
      id = 3;
      address = apps.genix.ip;
      cpus = { min = 1; max = 6; };
      memory = { min = "4G"; max = "24G"; };
      disk = { rootSize = "150G"; homeSize = "100G"; };
      seed = seedOf ./robotnix/genix.nix;
      selfManage.enable = true;
      git = {
        remoteUrl = "gitea@gitea.app.internal:Hermenix/genix.git";
        interval = "hourly";
      };
      hermes = {
        name = "Genix";
        environmentFiles = [ (secret "robots-genix") ];
        settings = {
          model = {
            provider = "commandcode";
            default = "deepseek/deepseek-v4.1-flash";
          };
          fallback_providers = [
            { provider = "anthropic"; model = "claude-haiku-5-5"; }
            { provider = "openrouter"; model = "deepseek/deepseek-v4.1-flash"; }
          ];
        };
      };
      allowDocker = true;
      # Survive a reseed (root is rebuilt from the git remote).
      persist = [
        "/var/lib/hermes"
        "/var/lib/docker"
      ];
      # Push/pull its flake over gitea's ssh.
      access.lanAccess = [
        { address = apps.gitea.ip; port = 22; }
      ];
    };
  };
}
