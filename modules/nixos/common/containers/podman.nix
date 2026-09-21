{ config, pkgs, lib, ... }:
let
  cfg = config.skyg.nixos.common.containers;
in
{
  config = lib.mkIf (cfg.enable && cfg.runtime == "podman") {
    virtualisation.oci-containers.backend = "podman";
    virtualisation = {
      podman = {
        enable = true;
        dockerCompat = true;
        defaultNetwork.settings.dns_enabled = true;
        dockerSocket.enable = true;
        autoPrune.enable = true;
      };
      # Allow pulling from local registries that serve plain HTTP
      # (e.g. minipc1.lab.internal:5001).
      containers.registries.insecure = cfg.localDockerRegistries;
    };
    environment.systemPackages = with pkgs; [ podman-compose podman-tui ];
  };
}
