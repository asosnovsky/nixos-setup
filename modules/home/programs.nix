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
}
