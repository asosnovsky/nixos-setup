{ hostName, homeMangerVersion, user }:
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
  home-manager.users.${user.name} = {
    home = {
      stateVersion = homeMangerVersion;
      shellAliases = {
        cat = "bat";
      };
      packages = [
        (pkgs.nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" ]; })
      ];
    };
    programs = {
      bat.enable = true;
      direnv.enable = true;
      lsd = {
        enable = true;
        enableAliases = true;
      };
      git = {
        enable = true;
        userName  = user.fullName;
        userEmail = user.email;
      };
      zsh = {
        enable = true;
        enableAutosuggestions = true;
      };
      zsh.oh-my-zsh = {
        enable = true;
        plugins = [
          "git"
          "sudo"
        ];
        theme = "robbyrussell";
      };
    };
  };
}