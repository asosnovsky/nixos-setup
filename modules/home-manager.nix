{ stateVersion }:
let
  gitconfigs =
    (builtins.filterSource (path: type: type != "directory") ./gitconfigs);
  gitconfigFiles = builtins.attrNames (builtins.readDir gitconfigs);
  makeCommonGitConfigs = { extraGitConfigs }: {
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
      ++ extraGitConfigs;
  };
  commonProgramsConfig = { pkgs }: {
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
in
{
  makeRootUser = { pkgs, ... }: {
    home = {
      stateVersion = stateVersion;
      shellAliases = {
        cat = "bat";
      };
    };
    programs = {
      git = {
        enable = true;
        userName = "root";
      } // (makeCommonGitConfigs { extraGitConfigs = [ ]; });
    } // (commonProgramsConfig { pkgs = pkgs; });
  };

  makeCommonUser =
    { enableDevelopmentKit
    , fullName
    , email
    , extraGitConfigs ? [ ]
    , ...
    }: { pkgs, ... }: {
      home = {
        stateVersion = stateVersion;
        shellAliases = {
          cat = "bat";
        };
        packages = with pkgs;
          [ jq nixpkgs-fmt ipfetch nixd ]
          ++ (if enableDevelopmentKit then [
            rye
            devenv
            uv
            devbox
            terraform
            kubectl
          ] else
            [ ]);
      };
      programs = {
        git = {
          enable = true;
          userName = fullName;
          userEmail = email;
        } // (makeCommonGitConfigs { extraGitConfigs = extraGitConfigs; });
      } // (commonProgramsConfig { pkgs = pkgs; });
    };
}
