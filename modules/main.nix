{ user
, systemStateVersion
, hostName
, ...
}:
{ lib, ... }: {
  imports = [
    ./core
    ./nixos
    ./network-drives.nix
  ];
  # Share defaults - using mkDefault so they can be overridden per-host
  skyg.user = {
    name = lib.mkDefault user.name;
    fullName = lib.mkDefault user.fullName;
    email = lib.mkDefault user.email;
  };
  skyg.core.hostName = hostName;
  skyg.home-manager.version = lib.mkDefault "24.11";
  system.stateVersion = systemStateVersion;
}
