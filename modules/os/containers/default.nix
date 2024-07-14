{ user, runtime ? null }:
{ pkgs, ... }: {
  virtualisation.containers.enable = true;
  environment.systemPackages = with pkgs; [ dive podman-tui ];
  imports = (if runtime == "podman" then
    [ (import ./podman.nix { user = user; }) ]
  else if runtime == "docker" then
    [ (import ./docker.nix { user = user; }) ]
  else
    [ ]);
}
