{ systemStateVersion }:
{ pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;
  system.stateVersion = systemStateVersion; 
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
    };
  };
}