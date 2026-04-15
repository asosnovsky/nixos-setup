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
    initContent = ''
            __cmd_start_time=$EPOCHSECONDS
            __cmd_has_run=0
            __last_cmd=""

            __record_start() {
              __cmd_start_time=''$EPOCHSECONDS
              __cmd_has_run=1
              __last_cmd="''$1"
            }
            __notify_onrecord_start() { __cmd_start_time=''$EPOCHSECONDS }
            __notify_on_finish() {
      	      if (( __cmd_has_run )); then
      	        local exit_code=''$?
      	        local elapsed=''$(( EPOCHSECONDS - __cmd_start_time ))
      	        if (( elapsed >= 5 )); then
      	          notify-send "''${__last_cmd} finished (''${elapsed}s)" "(exit: ''$exit_code)"
      	        fi
      				fi
              __cmd_start_time=''$EPOCHSECONDS
            }

            add-zsh-hook preexec __record_start
            add-zsh-hook precmd __notify_on_finish
    '';
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
  # ghostty = {
  #   enable = true;
  #   settings = {
  #     # Font Configuration
  #     font-size = 12;

  #     # Window Configuration
  #     window-decoration = false;
  #     window-padding-x = 12;
  #     window-padding-y = 12;
  #     background-opacity = 1.0;
  #     background-blur-radius = 32;

  #     # Cursor Configuration
  #     cursor-style = "block";
  #     cursor-style-blink = true;

  #     # Scrollback
  #     scrollback-limit = 3023;

  #     # Terminal features
  #     mouse-hide-while-typing = true;
  #     copy-on-select = false;
  #     confirm-close-surface = false;

  #     # Disable annoying copied to clipboard
  #     app-notifications = "no-clipboard-copy,no-config-reload";

  #     # Material 3 UI elements
  #     unfocused-split-opacity = 0.7;
  #     unfocused-split-fill = "#44464f";

  #     # Tab configuration
  #     gtk-titlebar = false;

  #     # Shell integration
  #     shell-integration = "detect";
  #     shell-integration-features = "cursor,sudo,title,no-cursor";

  #     # Rando stuff
  #     gtk-single-instance = true;

  #     # Theme
  #     theme = "dankcolors";
  #   };
  #   keybindings = {
  #     "ctrl+shift+n" = "new_window";
  #     "ctrl+t" = "new_tab";
  #     "ctrl+plus" = "increase_font_size:1";
  #     "ctrl+minus" = "decrease_font_size:1";
  #     "ctrl+zero" = "reset_font_size";
  #     "shift+enter" = "text:\\n";
  #   };
  #   themes = {
  #     dankcolors = {
  #       background = "#101418";
  #       foreground = "#e0e2e8";
  #       cursor-color = "#42a5f5";
  #       selection-background = "#0d47a1";
  #       selection-foreground = "#e0e2e8";
  #       palette = [
  #         "0=#101418"
  #         "1=#ff3270"
  #         "2=#42f558"
  #         "3=#fff332"
  #         "4=#1c8de8"
  #         "5=#003e71"
  #         "6=#42a5f5"
  #         "7=#e8f4ff"
  #         "8=#8d979f"
  #         "9=#ff739e"
  #         "10=#7cff8d"
  #         "11=#fff77c"
  #         "12=#60b8ff"
  #         "13=#7cc4ff"
  #         "14=#abd9ff"
  #         "15=#f5faff"
  #       ];
  #     };
  #   };
  # };
}
