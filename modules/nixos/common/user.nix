{ config, pkgs, ... }:
{
  users.users.root = {
    shell = pkgs.zsh;
  };
  users.users.${config.skyg.user.name} = {
    shell = pkgs.zsh;
    isNormalUser = true;
    description = config.skyg.user.name;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
  };
}
