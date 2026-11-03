{ config, lib, pkgs, skyg-secrets, ... }:
let
  homes = "/var/lib/slackerbot/homes";
  bazel = config.skyg.nixos.server.services.bazel-build;
  settings = {
    # The system each container boots (slackerbot's agent + bazel/rbuild);
    # updated on every rebuild.
    system = "${bazel.agentSystem}";
    # Shared Bazel download cache (/repo-cache) for the containers.
    rw_binds = bazel.binds.rw;
    ro_binds = bazel.binds.ro;
    machines_dir = "/var/lib/machines";
    state_dir = "/var/lib/slackerbot";
    agent_cwd = "/root";

    idle_timeout = "6h";
    max_idle_timeout = "0s";
    allow_indefinite = true;
    boot_timeout = "2m";

    container = { memory_mb = 4096; cpus = 1.0; };
    max_container = { memory_mb = 8192; cpus = 2.0; };
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
  # Off.
  config = lib.mkIf false {
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

    # Bazel build server for the containers (4 cores / 8 threads).
    skyg.nixos.server.services.bazel-build = {
      enable = true;
      cpuCount = 8;
      cacheGB = 50;
    };

    # Container links belong to systemd-networkd.
    networking.networkmanager.unmanaged = [ "interface-name:ve-*" ];
    networking.dhcpcd.denyInterfaces = [ "ve-*" ];
    # networkd only has the container links here (NetworkManager owns wlan),
    # so wait-online would always time out.
    systemd.network.wait-online.enable = false;

    systemd.tmpfiles.rules = [ "d ${homes} 0700 root root -" ];
  };
}
