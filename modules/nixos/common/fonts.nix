{ pkgs, ... }:
{
  fonts = {
    packages = with pkgs; [
      fira-code
      fira-code-symbols
      font-awesome
      mplus-outline-fonts.githubRelease
      jetbrains-mono
      ubuntu_font_family
      noto-fonts
      noto-fonts-cjk-sans
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
}
