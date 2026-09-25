#
# Clanker ! Do not modify this file!
#
{ config, lib, user, ... }:
{
  imports = [
    ./boot.nix
    ./file-system.nix
  ];
}
