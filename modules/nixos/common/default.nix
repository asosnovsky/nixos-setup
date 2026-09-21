{ ... }:
{
  imports = [
    ./hardware
    ./containers
    ./dns-records
    ./core.nix
    ./networking.nix
    ./user.nix
    ./fonts.nix
    ./ssh-server.nix
    ./qemu.nix
    ./binary-cache.nix
    ./pritunl
  ];
  config = {
    environment.sessionVariables.EDITOR = "vi";
    environment.localBinInPath = true;
  };
}
