{ user, runtime ? null, enableOnBoot ? false, localDockerRegistries ? [ ] }:
{ pkgs, ... }: {
  virtualisation.containers.enable = true;
  environment.systemPackages = with pkgs; [ dive ];
  imports = (if runtime == "podman" then
    [ (import ./podman.nix { user = user; localDockerRegistries = localDockerRegistries; }) ]
  else if runtime == "docker" then
    [
      (import ./docker.nix {
        user = user;
        enableOnBoot = enableOnBoot;
        localDockerRegistries = localDockerRegistries;
      })
    ]
  else
    [ ]);
}
