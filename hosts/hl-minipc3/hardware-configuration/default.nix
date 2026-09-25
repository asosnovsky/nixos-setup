#
# Clanker ! Do not modify this file!
#
{ config, lib, modulesPath, ... }:
{
  imports = [
    ./boot.nix
    ./file-system.nix
  ];
}
