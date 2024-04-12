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
        pkgs.kubectl
        pkgs.terraform
        pkgs.rye
        pkgs.glibc
        pkgs.betterdiscordctl
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
        envExtra = ''
          export KUBECONFIG=/run/media/ari/Data/local/kube/config.yml
        '';
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