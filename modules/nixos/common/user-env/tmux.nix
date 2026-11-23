{ config
, lib
, pkgs
, ...
}:
{
  config = lib.mkIf config.skyg.user.enable {
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
  };
}
