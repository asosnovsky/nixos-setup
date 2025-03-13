{ ... }:
{
  imports = [
    ./hardware
    ./containers
    ./core.nix
    ./networking.nix
    ./user.nix
    ./fonts.nix
    ./ssh-server.nix
    ./qemu.nix
    ./pritunl
  ];
}
