# sibli is ephemeral: root resets to this config on every start, so change
# things here (then rebuild the host), not inside the robot.
{ pkgs, ... }:
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
    zellij
  ];
  nixpkgs.config.allowUnfree = true;

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
