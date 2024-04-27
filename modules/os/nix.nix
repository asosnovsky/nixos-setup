{ systemStateVersion, user }:
{ pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;
  system.stateVersion = systemStateVersion;
  services.hydra.useSubstitutes = true;
  nix = {
    optimise = {
      automatic = true;
      dates = [ "01:00" ];
    };
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
    };
    settings.trusted-substituters = [
      "https://cache.flox.dev"
      "https://devenv.cachix.org"
    ];
    settings.trusted-users = [ "root" user.name ];
    settings.trusted-public-keys = [
      "flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs="
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
    ];
  };
}
