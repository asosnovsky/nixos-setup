{ user }:
{ pkgs, ... }:
{
  virtualisation.docker.enable = true;
  environment.systemPackages = with pkgs; [
    docker-compose
  ];
  users.users.${user.name}.extraGroups = [
    "docker"
  ];
}
