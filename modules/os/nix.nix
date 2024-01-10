{ systemStateVersion }:
{ pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = with pkgs; [
    git
    vscode
    nil	  
  ];
  system.stateVersion = systemStateVersion; 
}