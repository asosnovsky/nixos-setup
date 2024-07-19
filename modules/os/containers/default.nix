{ user, runtime ? null, enableOnBoot ? false }:
{ pkgs, ... }: {
  virtualisation.containers.enable = true;
  environment.systemPackages = with pkgs; [ dive ];
  imports = (if runtime == "podman" then
    [ (import ./podman.nix { user = user; }) ]
  else if runtime == "docker" then
    [
      (import ./docker.nix {
        user = user;
        enableOnBoot = enableOnBoot;
      })
    ]
  else
    [ ]);
}
