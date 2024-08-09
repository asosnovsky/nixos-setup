{ hostName, version, user, enableDevelopmentKit ? false, ... }:
{ pkgs, ... }:
{
  home-manager.users.root = {
    home.stateVersion = version;
    programs.git = {
      enable = true;
      userName = "root";
    };
    programs.zsh = {
      enable = true;
      autosuggestion.enable = true;
    };
    programs.zsh.oh-my-zsh.enable = true;
  };

}
