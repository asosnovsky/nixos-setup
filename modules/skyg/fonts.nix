{ config, pkgs, ... }:
{
  config = {
    fonts = {
      packages = with pkgs; [
        fira-code
        fira-code-symbols
        font-awesome
        mplus-outline-fonts.githubRelease
        noto-fonts-emoji
      ];
      enableDefaultPackages = true;
      fontDir.enable = true;
      fontconfig = {
        enable = true;
        defaultFonts = {
          serif = [ "Fira Code" "DroidSansMono" ];
          sansSerif = [ "Fira Code" "DroidSansMono" ];
          monospace = [ "Fira Code" ];
        };
      };
    };
  } // (if config.services.desktopManager.plasma6.enable then {
    services.desktopManager.plasma6.notoPackage = pkgs.fira-code;
  } else { });
}
