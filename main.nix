{
  systemStateVersion,
  hostName,
  user,
}:
{ ... }:
{
  imports =
    [ 
      /etc/nixos/hardware-configuration.nix
      (import ./modules/os/nix.nix {systemStateVersion = systemStateVersion;})
      (import ./modules/os/core.nix {hostName = hostName;})
      ./modules/os/services.nix
      ./modules/docker/core.nix
      (import ./modules/user.nix {user = user;})
    ];
}
