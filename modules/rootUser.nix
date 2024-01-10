{ hostName, systemStateVersion }:
{ pkgs, ... }:
{
  home-manager.users.root = {
    home.stateVersion = systemStateVersion;
    programs.git = {
      enable = true;
      userName  = "root";
      userEmail = "root@${hostName}";
    };
  };
}