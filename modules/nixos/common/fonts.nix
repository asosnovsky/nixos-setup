{ config, pkgs, lib, ... }:
let
  fullFontPackages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.droid-sans-mono
    nerd-fonts.fira-mono
    fira-code
    fira-code-symbols
    font-awesome
    mplus-outline-fonts.githubRelease
    jetbrains-mono
    ubuntu-classic
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
  ];
  minimalFontPackages = with pkgs; [
    fira-code
    noto-fonts
    noto-fonts-color-emoji
  ];
in
{
  options.skyg.nixos.common.fonts = {
    minimal = lib.mkOption {
      type = lib.types.bool;
      description = "Install only a minimal font set (for lean hosts).";
      default = false;
    };
  };
  config =
    let
      fontPackages = if config.skyg.nixos.common.fonts.minimal then minimalFontPackages else fullFontPackages;
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
    };
}
