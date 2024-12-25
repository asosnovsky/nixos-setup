{ user
, homeManagerVersion
, systemStateVersion
, hostName
, enableNetworkDrives ? false
  # Desktop Module
  # os
, os ? {
    enable = false;
  }
, localNixCaches ? { keys = [ ]; urls = [ ]; }
, ...
}:
{ pkgs, ... }: {
  imports = [
    ./core
    ./nixos
    ./network-drives.nix
  ];
  # Share defaults
  skyg.user = user;
  skyg.core.hostName = hostName;
  skyg.home-manager.version = homeManagerVersion;
  skyg.core.substituters = localNixCaches;
  skyg.nixos.common.containers = (if os.enable then os.containers else { });
  skyg.nixos.server.k8s = {
    masterIP = "10.0.10.6";
    masterHostName = "minipc1.lab.internal";
  };
  system.stateVersion = systemStateVersion;
}
