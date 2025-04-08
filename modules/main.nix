{ user
, homeManagerVersion
, systemStateVersion
, hostName
  # Desktop Module
  # os
, os ? {
    enable = false;
  }
, localNixCaches ? { keys = [ ]; urls = [ ]; }
, ...
}:
{ ... }: {
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
  system.stateVersion = systemStateVersion;
}
