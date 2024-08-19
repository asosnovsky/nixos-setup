{ ... }:
{
  imports = [
    ./hardware
    ./containers
    ./core.nix
    ./networking.nix
    ./user.nix
    ./ssh-server.nix
  ];
}
