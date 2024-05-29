{ user, system }:
{ pkgs, ... }: {
  services.nix-daemon.enable = true;
  security.pam.enableSudoTouchIdAuth = true;
  users.users.${user.name}.home = user.homepath;
  users.users.root.home = "/var/root";
  nixpkgs.hostPlatform = system;
}
