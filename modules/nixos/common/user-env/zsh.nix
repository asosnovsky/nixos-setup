{ config
, lib
, ...
}:
{
  config = lib.mkIf config.skyg.user.enable {
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

    skyg.configLinks.links.zshrc = {
      source = "shared/zsh/zshrc";
      target = ".zshrc";
      root = true;
    };
  };
}
