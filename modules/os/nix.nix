{ systemStateVersion }:
{ pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;
  system.stateVersion = systemStateVersion; 
  nix = {
    optimise = {
        automatic = true;
        dates = [ "01:00" ];
    };
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
    };
  };
}
