{ user, enableOnBoot ? false, localDockerRegistries ? [ ], ... }:
{ pkgs, ... }: {
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
    enableOnBoot = enableOnBoot;
    liveRestore = false;
    daemon.settings = {
      insecure-registries = localDockerRegistries;
    };
  };
  environment.systemPackages = with pkgs; [ docker-compose ];
  users.users.${user.name}.extraGroups = [ "docker" ];
}
