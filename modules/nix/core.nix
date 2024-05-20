{ user, systemStateVersion }:
{ pkgs, ... }:
{
  # Nix core
  system.stateVersion = systemStateVersion;
  nixpkgs.config.allowUnfree = true;
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-substituters = [
      "https://cache.flox.dev"
      "https://devenv.cachix.org"
    ];
    trusted-users = [ "root" user.name ];
    trusted-public-keys = [
      "flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs="
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
    ];
  };

  # System Packages
  programs.zsh.enable = true;
  environment.systemPackages = with pkgs; [
    # nix utils
    nix-index
    nil
    cachix

    # shell tools
    wget

  ];
  # Storage Optim
  nix.optimise.automatic = true;

}
