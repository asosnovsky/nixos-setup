{ user, systemStateVersion }:
{ pkgs, ... }:
{
  users.users.${user.name} = {
    # shell = pkgs.zsh;
    isNormalUser = true;
    description = user.name;
    extraGroups = [ 
      "networkmanager" 
      "wheel" 
      "docker"
    ];
    packages = with pkgs; [
      firefox
      bitwarden-cli
    ];
  };
  home-manager.users.${user.name} = {
    home = {
      stateVersion = systemStateVersion;
      shellAliases = {
        cat = "bat";
      };
      packages = [
        (pkgs.nerdfonts.override { fonts = [ "FiraCode" "DroidSansMono" ]; })
      ];
    };
    programs = {
      bat.enable = true;
      lsd = {
        enable = true;
        enableAliases = true;
      };
      git = {
        enable = true;
        userName  = user.fullName;
        userEmail = user.email;
      };
      zsh = {
        enable = true;
        enableAutosuggestions = true;
      };
      zsh.oh-my-zsh = {
        enable = true;
        plugins = [
          "git"
          "sudo"
        ];
        theme = "robbyrussell";
      };
    };
  };
}