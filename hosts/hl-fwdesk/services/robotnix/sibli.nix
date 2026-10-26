# sibli is ephemeral: root resets to this config on every start, so change
# things here (then rebuild the host), not inside the robot.
{ pkgs, ... }:
let
  # The robot's own nixpkgs has no host overlay, so build it from the repo.
  # Fine for the seed build; a rebuild inside the robot can't see this path.
  buzz-cli = pkgs.callPackage ../../../../pkgs/buzz-cli { };
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
    buzz-cli
  ];
  nixpkgs.config.allowUnfree = true;

  # direnv: hook into bash so the repo's devenv shims work.
  programs.bash = {
    enable = true;
    interactiveShellInit = ''
      eval "$(direnv hook bash)"
    '';
  };

  # Hermes's Buzz platform runs `buzz`; the service PATH has no system packages.
  services.hermes-agent.environment.BUZZ_CLI_PATH = "${buzz-cli}/bin/buzz";

  # Docker + compose. Needs allowDocker = true on the host.
  virtualisation.docker.enable = true;
  users.users.ari.extraGroups = [ "docker" ];

  # Own tailnet machine. Needs allowTun = true on the host.
  # Log in once: sudo tailscale up (state is kept via persist on the host)
  services.tailscale.enable = true;
  services.tailscale.openFirewall = true;
  networking.firewall.trustedInterfaces = [ "tailscale0" ];
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
}
