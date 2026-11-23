{ lib, ... }:
{
  imports = [
    ./hardware
    ./containers
    ./core.nix
    ./networking.nix
    ./user.nix
    ./user-env.nix
    ./config-links.nix
    ./hm-cleanup.nix # temporary, see the file
    ./fonts.nix
    ./ssh-server.nix
    ./qemu.nix
    ./binary-cache.nix
    ./pritunl
    ./diagnix
    ./dns
  ];
  config = {
    # Hosts with skyg.user.enable get nvim instead (user-env.nix).
    environment.sessionVariables.EDITOR = lib.mkDefault "vi";
    environment.localBinInPath = true;
  };
}
