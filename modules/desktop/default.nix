{ user
, enableX11 ? false
, enableGnome ? false
, enableKDE ? false
, enableHypr ? false
, enableWine ? false
}:
{ pkgs, ... }: {
  imports = [ ./wayland.nix ] ++ (if enableX11 then [ ./x11.nix ] else [ ])
    ++ (if enableGnome then [ ./gnome.nix ] else [ ])
    ++ (if enableWine then [ ./wine.nix ] else [ ])
    ++ (if enableKDE then [ ./kde.nix ] else [ ]) ++ (if enableHypr then
    [ (import ./hyprland.nix { user = user; }) ]
  else
    [ ]);

  # Flatpak
  services.flatpak.enable = true;
  # Mobile Connect
  programs.kdeconnect.enable = true;
  # Web
  # Personal Desktop App
  users.users.${user.name}.packages = with pkgs; [
    # web
    brave
    # mail
    thunderbird
    # password
    bitwarden-desktop
    rofi-rbw-wayland
    rofi-rbw-x11
    # development
    vscode
    # socials
    zoom-us
    betterdiscordctl
    discord
    signal-desktop
    whatsapp-for-linux
    caprine-bin # facebook messenger
    # crypto
    trezor-suite
    trezord
    ledger-live-desktop
    # documents
    onlyoffice-bin_latest
    # video
    vlc
    vlc-bittorrent
    # terminal
    alacritty
    alacritty-theme
  ];
  # udev rules for crypto wallets
  services.udev.packages = with pkgs; [ ledger-udev-rules trezor-udev-rules ];
}
