{ config, pkgs, nbot, skyg-secrets, ... }:
let
  homes = "/var/lib/nbot/homes";
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
  age.secrets.nbot-cluster = {
    file = skyg-secrets.nbot-cluster;
    owner = "root";
    mode = "0400";
  };

  # nbot flake input; options and docs in its repo.
  services.nbot = {
    enable = true;
    mode = "slave";
    configFile = (pkgs.formats.toml { }).generate "nbot.toml" settings;
    environmentFile = config.age.secrets.nbot-cluster.path;
  };

  # Container links belong to systemd-networkd.
  networking.networkmanager.unmanaged = [ "interface-name:ve-*" ];
  networking.dhcpcd.denyInterfaces = [ "ve-*" ];
  # networkd only has the container links here (NetworkManager owns wlan),
  # so wait-online would always time out.
  systemd.network.wait-online.enable = false;

  systemd.tmpfiles.rules = [ "d ${homes} 0700 root root -" ];
}
