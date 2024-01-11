{ systemStateVersion }:
{ pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;
  system.stateVersion = systemStateVersion; 
}