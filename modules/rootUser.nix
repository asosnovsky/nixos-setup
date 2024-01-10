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
    programs.zsh = {
      enable = true;
      enableAutosuggestions = true;
    };
    programs.zsh.oh-my-zsh.enable = true;
  };
}