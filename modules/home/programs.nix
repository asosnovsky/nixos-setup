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
  direnv = {
    enable = true;
    enableNushellIntegration = true;
  };
  lsd = {
    enable = false;
    enableBashIntegration = true;
    enableZshIntegration = true;
    colors = "auto";
    # git = true;
    icons = "always";
  };
  fastfetch = {
    enable = true;
  };
  eza = {
    enable = true;
    enableNushellIntegration = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };
  starship = {
    enable = true;
    enableNushellIntegration = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    settings = {
      add_newline = true;
      env_var = {
        variable = "SHELL";
        default = "unknown shell";
      };
      battery = {
        disabled = false;
      };
      time = {
        disabled = false;
      };
      kubernetes = {
        disabled = false;
      };
      nix_shell = {
        disabled = false;
      };
      localip = {
        disabled = false;
        ssh_only = false;
      };
      hostname = {
        disabled = false;
        ssh_only = false;
      };
      direnv = {
        disabled = false;
      };
      gcloud = {
        disabled = true;
      };
      sudo = {
        disabled = false;
      };
      memory_usage = {
        disabled = false;
      };
    };
  };
  nushell = {
    enable = true;
    extraConfig = ''
      $env.config.show_banner = false
    '';
    plugins = with pkgs.nushellPlugins; [
      polars
      # net
      highlight
    ];
  };
  carapace = {
    enable = true;
    enableNushellIntegration = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };
  # environment.pathsToLink = [ "/share/zsh" ];
  zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion = {
      enable = true;
      strategy = [
        "match_prev_cmd"
        "history"
        "completion"
      ];
    };
    syntaxHighlighting.enable = true;
  };
  zellij = {
    enable = true;
    settings = {
      theme = "nord";
      session_serialization = false;
      show_startup_tips = false;
    };
  };
  tmux = {
    enable = true;
    clock24 = true;
    mouse = true;
    plugins = with pkgs.tmuxPlugins; [ nord cpu sidebar ];
    extraConfig = ''
      set -g status-right '#{cpu_bg_color} CPU: #{cpu_icon} #{cpu_percentage} | %a %h-%d %H:%M '
    '';
  };
}
