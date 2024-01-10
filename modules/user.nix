{ user, systemStateVersion }:
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
  home-manager.users.${user.name} = {
    home.stateVersion = systemStateVersion;
    programs.git = {
      enable = true;
      userName  = user.gitUser;
      userEmail = user.email;
    };
  };
}