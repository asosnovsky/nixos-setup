{ user }:
{ pkgs, ... }:
{
  users.users.${user.name} = {
    shell = pkgs.zsh;
    isNormalUser = true;
    description = user.name;
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
    ];
    packages = with pkgs; [
      nixd
    ];
  };
}
