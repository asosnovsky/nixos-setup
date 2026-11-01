{ config, pkgs, slackerbot, skyg-secrets, ... }:
let
  homes = "/var/lib/slackerbot/homes";
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

    container = { memory_mb = 1024; cpus = 1.0; };
    max_container = { memory_mb = 4096; cpus = 2.0; };
    host_reserve = { memory_mb = 8192; cpus = 2.0; };
    storage = { min = "2G"; max = "5G"; limit = "20G"; };
    drives = [{ path = homes; reserve = "100G"; }];

    # Worker of the master on fwdesk. Slack tokens and goose settings come
    # from the master. Trusts the first certificate it sees (saved in
    # state_dir/master.fingerprint); pin it in master_fingerprint if wanted.
    cluster = {
      secret = "$CLUSTER_SECRET";
      master = "wss://fwdesk.lab.internal:7946";
    };
  };
in
{
  age.secrets.slackerbot-cluster = {
    file = skyg-secrets.slackerbot-cluster;
    owner = "root";
    mode = "0400";
  };

  # slackerbot flake input; options and docs in its repo.
  services.slackerbot = {
    enable = true;
    mode = "slave";
    configFile = (pkgs.formats.toml { }).generate "slackerbot.toml" settings;
    environmentFile = config.age.secrets.slackerbot-cluster.path;
  };

  # Container links belong to systemd-networkd.
  networking.networkmanager.unmanaged = [ "interface-name:ve-*" ];
  networking.dhcpcd.denyInterfaces = [ "ve-*" ];

  systemd.tmpfiles.rules = [ "d ${homes} 0700 root root -" ];
}
