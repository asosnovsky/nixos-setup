{ config
, lib
, pkgs
, ...
}:
{
  config = lib.mkIf config.skyg.user.enable {
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
  };
}
