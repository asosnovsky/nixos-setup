{ config, pkgs, lib, ... }:

let
  cfg = config.skyg.nixos.common.containers;
in
{
  config = lib.mkIf (cfg.runtime == "docker") {
    virtualisation.docker = {
      enable = true;
      autoPrune.enable = true;
      enableOnBoot = cfg.enableOnBoot;
      liveRestore = false;
      daemon.settings = {
        insecure-registries = cfg.localDockerRegistries;
        metrics-addr = "127.0.0.1:${toString cfg.metricsPort}";
      };
    };
    environment.systemPackages = with pkgs; [ docker-compose ];
    users.users.${config.skyg.user.name}.extraGroups = [ "docker" ];
    virtualisation.oci-containers.backend = "docker";
    networking.firewall.allowedUDPPorts =
      (if cfg.openMetricsPort then [
        cfg.metricsPort
      ] else [ ]);
    networking.firewall.allowedTCPPorts =
      (if cfg.openMetricsPort then [
        cfg.metricsPort
      ] else [ ]);

  };
}
