{ hostName, homeMangerVersion, user }:
{ pkgs, ... }:
let
  gitconfigs =
    (builtins.filterSource (path: type: type != "directory") ../../configs/gitconfigs);
  gitconfigFiles = builtins.attrNames (builtins.readDir gitconfigs);
in
{
  home-manager.users.root = {
    home.stateVersion = homeMangerVersion;
    programs.git = {
      enable = true;
      userName = "root";
      userEmail = "root@${hostName}";
    };
    programs.zsh = {
      enable = true;
      autosuggestion.enable = true;
    };
    programs.zsh.oh-my-zsh.enable = true;
  };
  home-manager.users.${user.name} = {
    home = {
      stateVersion = homeMangerVersion;
      shellAliases = { cat = "bat"; };
      packages = with pkgs; [
        kubectl
        terraform
        rye
        betterdiscordctl
        discord
        devenv
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
        userName = user.fullName;
        userEmail = user.email;
        delta = { enable = true; };
        extraConfig = {
          color = { ui = "auto"; };
          push = {
            default = "upstream";
            autoSetupRemote = true;
          };
          init = { defaultBranch = "main"; };
        };
        includes =
          (builtins.map (f: { path = gitconfigs + "/" + f; }) gitconfigFiles);
      };
      zsh = {
        enable = true;
        autosuggestion.enable = true;
      };
      zsh.oh-my-zsh = {
        enable = true;
        plugins = [ "git" "sudo" ];
        theme = "robbyrussell";
      };
      helix = {
        enable = true;
      };
    };
  };
}
