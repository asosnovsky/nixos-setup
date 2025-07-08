{ pkgs, ... }:
let
  fontPackages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.droid-sans-mono
    nerd-fonts.fira-mono
    fira-code
    fira-code-symbols
    font-awesome
    mplus-outline-fonts.githubRelease
    jetbrains-mono
    ubuntu_font_family
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    noto-fonts-color-emoji
  ];
in
{
  environment.systemPackages = fontPackages;
  fonts = {
    packages = fontPackages;
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

