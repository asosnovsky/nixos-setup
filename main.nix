{
  systemStateVersion ? "23.05",
  hostName,
  user,
}:
{ ... }:
let 
    home-manager = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/release-${systemStateVersion}.tar.gz";
in
{
  imports =
    [ 
      /etc/nixos/hardware-configuration.nix
      (import ./modules/os/nix.nix {
        systemStateVersion = systemStateVersion;
      })
      (import ./modules/os/core.nix {
        hostName = hostName;
      })
      (import "${home-manager}/nixos")
      ./modules/os/services.nix
      ./modules/docker/core.nix
      (import ./modules/user.nix {
        user = user;
        systemStateVersion = systemStateVersion;
      })
      (import ./modules/rootUser.nix {
        hostName = hostName;
        systemStateVersion = systemStateVersion;
      })
    ];
}
