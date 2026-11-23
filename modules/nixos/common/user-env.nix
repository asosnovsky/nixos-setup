{ config
, lib
, pkgs
, ...
}:
let
  cfg = config.skyg.user;

  # Nushell plugin registry with the polars plugin added.
  nuPluginRegistry = pkgs.runCommandLocal "nu-plugin.msgpackz" { } ''
    export HOME="$TMPDIR"
    touch config.nu env.nu
    ${pkgs.nushell}/bin/nu \
      --config config.nu \
      --env-config env.nu \
      --plugin-config plugin.msgpackz \
      --no-history \
      --no-std-lib \
      --commands 'plugin add ${pkgs.nushellPlugins.polars}/bin/nu_plugin_polars'
    cp plugin.msgpackz "$out"
  '';
in
{
  # Shell and CLI setup for the main user and root (skyg.user.enable).
  # Tools and anything needing a store path are NixOS options here; plain
  # dotfiles live in configs/shared and are linked by skyg.configLinks.
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      jq
      htop
      kubectl
      kubectx
      nixpkgs-fmt
      nixd
      ipfetch
      fastfetch
      terraform
      eza
      carapace
      delta
      zellij
      nushell
    ];

    environment.shellAliases = {
      cat = "bat";
      ls = "eza";
      ll = "eza -l";
      la = "eza -a";
      lla = "eza -la";
      lt = "eza --tree";
      open-this = "xdg-open";
    };

    programs.zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestions = {
        enable = true;
        strategy = [
          "match_prev_cmd"
          "history"
          "completion"
        ];
      };
      syntaxHighlighting.enable = true;
      histSize = 10000;
      setOptions = [
        "HIST_FCNTL_LOCK"
        "HIST_IGNORE_DUPS"
        "HIST_IGNORE_SPACE"
        "SHARE_HISTORY"
      ];
      # No first-run wizard for a user whose ~/.zshrc is not linked yet.
      shellInit = ''
        zsh-newuser-install() { :; }
      '';
    };

    # Prompt init for zsh and bash; settings are in configs/shared/starship.toml.
    programs.starship.enable = true;

    programs.direnv = {
      enable = true;
      nix-direnv.enable = false;
    };

    programs.bat = {
      enable = true;
      settings.theme = "gruvbox-dark";
    };

    programs.neovim = {
      enable = true;
      defaultEditor = true;
      viAlias = true;
      vimAlias = true;
      configure.packages.skyg.start = with pkgs.vimPlugins; [
        nvim-lspconfig
        nvim-treesitter.withAllGrammars
        telescope-cheat-nvim
        yuck-vim
        statix
      ];
    };
    environment.sessionVariables.VISUAL = "nvim";

    programs.tmux = {
      enable = true;
      clock24 = true;
      escapeTime = 10;
      plugins = with pkgs.tmuxPlugins; [ nord cpu sidebar ];
      extraConfigBeforePlugins = ''
        set -g mouse on
      '';
      extraConfig = ''
        set -g status-right '#{cpu_bg_color} CPU: #{cpu_icon} #{cpu_percentage} | %a %h-%d %H:%M '
      '';
    };

    # Identity is system-wide; the rest is configs/shared/git/config.
    programs.git = {
      enable = true;
      config = {
        user = {
          name = cfg.fullName;
          email = cfg.email;
        };
      } // lib.optionalAttrs (cfg.extraGitConfigs != [ ]) {
        include.path = map (c: c.path) cfg.extraGitConfigs;
      };
    };

    programs.gnupg.agent = {
      enable = true;
      settings.default-cache-ttl = 1800;
    };

    skyg.configLinks.links = {
      zshrc = {
        source = "shared/zsh/zshrc";
        target = ".zshrc";
        root = true;
      };
      starship = {
        source = "shared/starship.toml";
        target = ".config/starship.toml";
        root = true;
      };
      git = {
        source = "shared/git/config";
        target = ".config/git/config";
        root = true;
      };
      zellij = {
        source = "shared/zellij/config.kdl";
        target = ".config/zellij/config.kdl";
        root = true;
      };
      nushell = {
        source = "shared/nushell/config.nu";
        target = ".config/nushell/config.nu";
        root = true;
      };
      nushell-plugins = {
        storePath = nuPluginRegistry;
        target = ".config/nushell/plugin.msgpackz";
        root = true;
      };
    };
  };
}
