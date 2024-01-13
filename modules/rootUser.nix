{ hostName, homeMangerVersion }:
{ pkgs, ... }:
{
  home-manager.users.root = {
    home.stateVersion = homeMangerVersion;
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