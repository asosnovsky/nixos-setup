{ pkgs, ... }:
{
  # Flatpak
  services.flatpak.enable = true;
  # Mobile Connect
  programs.kdeconnect.enable = true;
  environment.systemPackages = with pkgs; [
    # copy to clipboard
    wl-clipboard-x11
    xclip
    # socials
    slack
    zoom-us
    betterdiscordctl
    discord
    signal-desktop
    whatsapp-for-linux
    caprine-bin # facebook messenger

    # development
    vscode

    # web
    brave

    # mail
    thunderbird

    # password
    bitwarden-desktop

    # documents
    onlyoffice-bin_latest

    # video
    vlc
    vlc-bittorrent

    # terminal
    alacritty
    alacritty-theme

    # wine
    wineWowPackages.stable
    winetricks
    wineWowPackages.waylandFull
  ];
}
