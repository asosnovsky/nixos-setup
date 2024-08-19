{ ... }:
{
  imports = [
    ./hardware
    ./core.nix
    ./networking.nix
    ./user.nix
    ./ssh-server.nix
  ];
}
