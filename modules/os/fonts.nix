{ pkgs, ... }:
{
  # Fonts
  fonts = {
    packages = with pkgs; [
      fira-code
      fira-code-symbols
      font-awesome
      liberation_ttf
      mplus-outline-fonts.githubRelease
      nerdfonts
      noto-fonts
      noto-fonts-emoji
      proggyfonts
      flatpak
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
}
