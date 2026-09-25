{ config, pkgs, skyg-secrets, ... }:
let
  ports = {
    nixServe = 5000;
    dockerRegistry = 5001;
    postgresIU = 7491;
    ssh = 22;
    iu = 1947;
  };
  gitea = {
    user = "gitea";
    group = "gitea";
    stateDir = "/var/lib/sosnovsky/gitea";
    sshPort = 2222;
    httpPort = 3000;
  };
  openPorts = [
    ports.nixServe
    ports.dockerRegistry
    gitea.sshPort
    gitea.httpPort
    ports.postgresIU
    ports.ssh
    ports.iu
  ];
  buzz-manage = pkgs.writeShellScriptBin "buzz-manage" ''
    export BUZZ_ENV_FILE="${config.age.secrets.buzz-env.path}"
    export BUZZ_COMPOSE_BIN="${pkgs.docker-compose}/bin/docker-compose"
    ${builtins.readFile ../scripts/hl-minipc1/buzz-manage.sh}
  '';
in
{
  imports = [
    ./containers.nix
    ./services
    ./hardware-configuration
    ./hardware.nix
  ];

  skyg.user.enable = true;
  skyg.nixos.common.ssh-server.enable = true;
  skyg.server.dns.routing = {
    enable = false;
    openFirewall = true;
    addressesSecretName = "dns-addresses.conf";
  };
  skyg.nixos.common.containers.runtime = "docker";
  skyg.nixos.common.containers.openMetricsPort = true;
  skyg.nixos.common.containers.networks.ipvlanLab = {
    enable = true;
    parent = "eno1";
    ipRange = "10.0.101.16/28";
  };
  skyg.server.admin.enable = true;
  skyg.server.exporters.enable = true;
  skyg.nixos.server.k3s.enable = false;
  skyg.networkDrives.enable = true;

  age.secrets.buzz-env.file = skyg-secrets.buzz-env;

  environment.systemPackages = [ buzz-manage ];

  networking.firewall.allowedUDPPorts = openPorts;
  networking.firewall.allowedTCPPorts = openPorts;
}
