{
  systemStateVersion ? "23.11",
  homeMangerVersion ? "23.11",
  hostName,
  user,
  enableSSHServer ? false,
  firewall ? {enable = true;},
  enableFingerPrint ? false,
}:
{ pkgs, ... }:
let 
    home-manager = builtins.fetchTarball "https://github.com/nix-community/home-manager/archive/release-${homeMangerVersion}.tar.gz";
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
        firewall = firewall;
      })
      (import ./modules/os/hardware.nix {
        enableFingerPrint = enableFingerPrint;
      })
      (import ./modules/os/ssh.nix {
        user = user;
        enableSSHServer = enableSSHServer;
      })
      (import "${home-manager}/nixos")
      ./modules/os/services.nix
      ./modules/docker/core.nix
      (import ./modules/user.nix {
        user = user;
        homeMangerVersion = homeMangerVersion;
      })
      (import ./modules/rootUser.nix {
        hostName = hostName;
        homeMangerVersion = homeMangerVersion;
      })
    ];
}
