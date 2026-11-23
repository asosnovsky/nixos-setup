{ config
, lib
, ...
}:
{
  config = lib.mkIf config.skyg.user.enable {
    # Prompt init for zsh and bash; settings are in configs/shared/starship.toml.
    programs.starship.enable = true;

    skyg.configLinks.links.starship = {
      source = "shared/starship.toml";
      target = ".config/starship.toml";
      root = true;
    };
  };
}
