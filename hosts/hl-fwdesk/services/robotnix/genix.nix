# genix's starting NixOS config (a robotnix seed, not a host module).
#
# The host copies this into the robot's /etc/nixos on first install and on
# `robotnix reseed`. After that the robot owns it. Inside the robot:
#   sudo nixos-rebuild switch --flake /etc/nixos
# Host-managed basics (network, ssh, user) live in /etc/nixos/robotnix.nix.
{ pkgs, ... }:
{
  # The user has no password; ssh keys only.
  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    git
    vim
    curl
    htop
  ];

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
}
