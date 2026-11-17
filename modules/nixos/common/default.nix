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
    ./binary-cache.nix
    ./pritunl
    ./dns
  ];
  config = {
    environment.sessionVariables.EDITOR = "vi";
    environment.localBinInPath = true;
  };
}
