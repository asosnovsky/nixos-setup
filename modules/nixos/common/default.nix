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
  config = {
    environment.sessionVariables.EDITOR = "vi";
    environment.sessionVariables.NIXPKGS_ALLOW_UNFREE = 1;
    environment.localBinInPath = true;
  };
}
