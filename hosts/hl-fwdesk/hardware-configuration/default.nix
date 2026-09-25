#
# Clanker ! Do not modify this file!
#
{ config, lib, pkgs, modulesPath, ... }:
{
  imports = [
    ./boot.nix
    ./file-system.nix
  ];
}
