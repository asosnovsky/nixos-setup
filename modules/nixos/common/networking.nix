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
    skyg.nixos.common.networking = {
      nfsServer.enable = lib.mkOption {
        description = "Enable the NFS server (services.nfs.server).";
        type = lib.types.bool;
        default = true;
      };
    };
  };
  config = {
    # Define hostname.
    networking.hostName = cfg.hostName;

    # Enable networking
    networking.networkmanager.enable = true;

    # NFS Support
    services.nfs.server.enable = config.skyg.nixos.common.networking.nfsServer.enable;

    # Disable the flaky nm service
    systemd.services.NetworkManager-wait-online.enable = false;
  };
}
