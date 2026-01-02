{ user
, homeManagerVersion
, systemStateVersion
, hostName
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
  system.stateVersion = systemStateVersion;
}
