{ config, lib, ... }:
let
  cfg = config.skyg.core;
in
{
  options = {
    skyg.core = {
      hostName = lib.mkOption {
        description = "Machine Hostname";
        type = lib.types.str;
      };
    };
  };
  config = {
    # Define hostname.
    networking.hostName = cfg.hostName;

    # Enable networking
    networking.networkmanager.enable = true;

    # NFS Support
    services.nfs.server.enable = true;

    # Tailscale
    services.tailscale.enable = true;
    services.tailscale.useRoutingFeatures = "client";

    # Disable the flaky nm service
    systemd.services.NetworkManager-wait-online.enable = false;
  };
}
