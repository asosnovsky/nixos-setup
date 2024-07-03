{ pkgs, ... }: {
  services.desktopManager.plasma6.enable = true;
  services.desktopManager.plasma6.notoPackage = pkgs.fira-code;
  services.desktopManager.plasma6.enableQt5Integration = true;
  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    konsole # terminal
    elisa # media player
    kate # text editor
    gwenview # image viewer
  ];
  environment.systemPackages = with pkgs; [
    kdePackages.plasma-browser-integration
    konsave # save configs
  ];
}
