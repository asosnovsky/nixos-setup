# genix's starting config. It is persistent and manages itself: after the
# first install this (copied to /etc/nixos/seed/...) belongs to genix, which
# changes and applies its own system with robotnix-apply. Edits here only
# matter for a fresh install with nothing on its git remote.
{ ... }:
{
  imports = [
    ./common.nix
    ./buzz.nix
  ];

  skyg.robot.buzz.enable = true;
}
