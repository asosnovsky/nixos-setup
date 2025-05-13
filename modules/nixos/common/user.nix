{ config, pkgs, ... }:
{
  users.users.root = {
    shell = pkgs.nushell;
  };
  users.users.${config.skyg.user.name} = {
    shell = pkgs.nushell;
    isNormalUser = true;
    description = config.skyg.user.name;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
  };
}
