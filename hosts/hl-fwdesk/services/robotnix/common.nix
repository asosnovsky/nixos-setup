# Shared base for this host's robots (sibli, genix). Robots get a copy under
# /etc/nixos/seed (see seedOf in ../robotnix.nix), so a robot that rebuilds
# itself keeps working; edit it here for new installs and ephemeral robots.
{ config, lib, pkgs, ... }:
let
  user = config.robotnix.user;
in
{
  # The user has no password; ssh keys only.
  security.sudo.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    git
    vim
    curl
    htop
    claude-code
    devenv
    direnv
    (python3.withPackages (ps: [ ps.pip ]))
    nodejs
    docker-compose
    zellij
  ];
  nixpkgs.config.allowUnfree = true;

  # direnv: hook into bash so the repo's devenv shims work.
  programs.bash = {
    enable = true;
    interactiveShellInit = ''
      eval "$(direnv hook bash)"
    '';
  };

  # Docker + compose. Needs allowDocker = true on the host.
  virtualisation.docker.enable = true;
  users.users.${user}.extraGroups = [ "docker" ];
  users.users.hermes.extraGroups = lib.mkIf config.robotnix.hermes.enable [ "docker" ];

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
}
