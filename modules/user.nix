{ user }:
{ pkgs, ... }:
{
  users.users.${user.name} = {
    isNormalUser = true;
    description = user.name;
    extraGroups = [ 
      "networkmanager" 
      "wheel" 
      "docker"
    ];
    packages = with pkgs; [
      firefox
    ];
  };
}