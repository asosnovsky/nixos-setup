{ config, pkgs, lib, ... }:
let
  cfg = config.skyg.nixos.common.containers;
in
{
  config = lib.mkIf (cfg.runtime == "podman") {
    virtualisation.oci-containers.backend = "podman";
    virtualisation = {
      podman = {
        enable = true;
        dockerCompat = true;
        defaultNetwork.settings.dns_enabled = true;
        dockerSocket.enable = true;
        autoPrune.enable = true;
      };
    };
    environment.systemPackages = with pkgs; [ podman-compose podman-tui ];
  };
}
