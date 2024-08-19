{ ... }:
{
  imports = [
    ./hardware
    ./core.nix
    ./user.nix
    ./ssh-server.nix
  ];
}
