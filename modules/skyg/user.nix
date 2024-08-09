{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.skyg;
  gitconfigs =
    (builtins.filterSource (path: type: type != "directory") ./gitconfigs);
  gitconfigFiles = builtins.attrNames (builtins.readDir gitconfigs);

in
{
  options = {
    skyg.home-manager.version = mkOption {
      type = types.str;
    };
    skyg.user = {
      name = mkOption {
        type = types.str;
      };
      fullName = mkOption {
        type = types.str;
      };
      email = mkOption {
        type = types.str;
      };
      extraGitConfigs = mkOption {
        type = types.listOf (types.submodule {
          path = mkOption {
            type = types.str;
          };
        });
        default = [ ];
      };
      enableDevelopmentKit = mkOption {
        type = types.bool;
        default = false;
      };
    };
  };

  config = {
    programs.zsh.enable = true;
    home-manager.users.root = {
      home.stateVersion = cfg.home-manager.version;
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
    home-manager.users.${cfg.user.name} = {
      home = {
        sessionVariables = { };
        stateVersion = cfg.home-manager.version;
        shellAliases = {
          cat = "bat";
        };
        packages = with pkgs;
          [ jq nixfmt-classic devenv ipfetch nixd ]
          ++ (if cfg.user.enableDevelopmentKit then [
            rye
            uv
            devbox
            terraform
            kubectl
          ] else
            [ ]);
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
          userName = cfg.user.fullName;
          userEmail = cfg.user.email;
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
            (builtins.map (f: { path = gitconfigs + "/" + f; }) gitconfigFiles)
            ++ cfg.user.extraGitConfigs;
        };
        zsh = {
          enable = true;
          autosuggestion.enable = true;
          initExtra = ''
            export PROMPT='%(!.%{%F{yellow}%}.)$USER@%{$fg[white]%}%M %{$fg[cyan]%}%c%{$reset_color%} $(git_prompt_info)'
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
          plugins = with pkgs.tmuxPlugins; [ nord cpu battery sidebar ];
        };
      };
    };
  };
}


# user = {
#   name = "ari";
#   fullName = "Ari Sosnovsky";
#   email = "ariel@sosnovsky.ca";
# };
# sumoUser = rec {
#   name = "asosnovsky";
#   fullName = user.fullName;
#   email = "${name}@sumologic.com";
#   homepath = "/Users/${name}";
#   extraGitConfigs = [{ path = "${homepath}/.config/mysumo/gitconfig"; }];
# };
