{ pkgs, ... }:
{
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
        "~/.config/alacritty/themes/themes/nord.toml"
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
        # program = pkgs.zsh;
        args = [
          "-l"
          "-c"
          "tmux attach || tmux"
        ];
      };
    };
  };
}
