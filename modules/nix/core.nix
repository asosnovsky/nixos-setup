{ user, systemStateVersion }:
{ pkgs, ... }:
{
  # Nix core
  system.stateVersion = systemStateVersion;
  nixpkgs.config.allowUnfree = true;
  services.hydra.useSubstitutes = true;
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
  # Set your time zone.
  time.timeZone = "America/Toronto";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_CA.UTF-8";

  # System Packages
  programs.zsh.enable = true;
  programs.nix-ld.enable = true;
  environment.systemPackages = with pkgs; [
    # nix utils
    nix-index
    nil
    cachix

    # shell tools
    wget

    # misc
    glib
    glibc
  ];
  # Storage Optim
  nix.optimise.automatic = true;
  nix.optimise.dates = [ "01:00" ];
  services.cron = {
    enable = true;
    systemCronJobs = [
      "* 23 * * *       root    nix-collect-garbage --delete-older-than 1d"
      "* 23 * * *       ${user.name}   nix-collect-garbage --delete-older-than 1d"
    ];
  };
}