{ pkgs, user, ... }:
{
  bat.enable = true;
  neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    plugins = with pkgs.vimPlugins; [
      nvim-lspconfig
      nvim-treesitter.withAllGrammars
      telescope-cheat-nvim
      yuck-vim
      statix
    ];
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
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "sudo" ];
      theme = "robbyrussell";
    };
  };
  tmux = {
    enable = true;
    clock24 = true;
    mouse = true;
    plugins = with pkgs.tmuxPlugins; [ nord cpu battery sidebar ];
  };
  alacritty = {
    enable = true;
    settings = {
      import = [
        "${pkgs.alacritty-theme}/nord.toml"
      ];
      window = {
        title = "Terminal";
        blur = true;
      };
      font = {
        normal = { family = "Fira Code"; style = "Regular"; };
        bold = { family = "Fira Code"; style = "Bold"; };
        italic = { family = "Fira Code"; style = "Italic"; };
      };
      shell = {
        program = "/home/${user.name}/.nix-profile/bin/zsh";
        args = [
          "-l"
          "-c"
          "tmux attach || tmux"
        ];
      };
    };
  };
}
