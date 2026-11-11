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
    ./diagnix
    ./qemu.nix
    ./binary-cache.nix
    ./pritunl
  ];
  config = {
    environment.sessionVariables.EDITOR = "vi";
    environment.localBinInPath = true;
  };
}
