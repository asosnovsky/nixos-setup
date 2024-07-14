{ user }:
{ pkgs, ... }: {
  virtualisation.docker.enable = true;
  virtualisation.docker.autoPrune.enable = true;
  virtualisation.docker.enableOnBoot = false;
  virtualisation.docker.liveRestore = false;
  environment.systemPackages = with pkgs; [ docker-compose ];
  users.users.${user.name}.extraGroups = [ "docker" ];
}
