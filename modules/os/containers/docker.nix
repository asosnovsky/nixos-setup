{ user }:
{ pkgs, ... }: {
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
    enableOnBoot = false;
    liveRestore = false;
  };
  environment.systemPackages = with pkgs; [ docker-compose ];
  users.users.${user.name}.extraGroups = [ "docker" ];
}
