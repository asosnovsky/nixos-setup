{ hostName, homeMangerVersion, user }:
{ pkgs, ... }:
let
  gitconfigs =
    (builtins.filterSource (path: type: type != "directory") ./gitconfigs);
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
      sessionVariables = {
        MAMBA_ROOT_PREFIX = "$HOME/.local/micromamba";
      };
      stateVersion = homeMangerVersion;
      shellAliases = {
        cat = "bat";
        conda = "micromamba";
      };
      packages = with pkgs; [
        jq
        nixfmt-classic
        kubectl
        terraform
        rye
        devenv
        micromamba
        neofetch
        ipfetch
        nixd
      ];
    };
    programs = {
      bat.enable = true;
      neovim = {
        enable = true;
        defaultEditor = true;
        viAlias = true;
        vimAlias = true;
      };
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
        initExtra = ''
          micromamba shell init --shell zsh --root-prefix=$HOME/.local/micromamba
        '';
      };
      zsh.oh-my-zsh = {
        enable = true;
        plugins = [ "git" "sudo" ];
        theme = "robbyrussell";
      };
      tmux = {
        enable = true;
        clock24 = true;
        mouse = true;
        plugins = with pkgs.tmuxPlugins; [
          nord
          cpu
          battery
          sidebar
        ];
      };
    };
  };
}
