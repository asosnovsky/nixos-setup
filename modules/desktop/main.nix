{ user
, enableX11 ? false
, enableGnome ? false
, enableKDE ? false
, enableHypr ? false
, enableWine ? false
}:
{ pkgs, ... }:
{
  imports = [
    ./wayland.nix
  ] ++ (if enableX11 then [
    ./x11.nix
  ] else [ ]) ++ (if enableGnome then [
    ./gnome.nix
  ] else [ ]) ++ (if enableWine then [
    ./wine.nix
  ] else [ ]) ++ (if enableKDE then [
    ./kde.nix
  ] else [ ]) ++ (if enableHypr then [
    (import ./hyprland.nix {
      user = user;
    })
  ] else [ ]);

  # Useful Desktop Apps
  programs.kdeconnect.enable = true;
  # Personal Desktop App
  users.users.${user.name}.packages = with pkgs; [
    # web
    firefox
    brave
    # password
    bitwarden-cli
    # development
    vscode
    # socials
    zoom-us
    betterdiscordctl
    discord
    # crypto
    trezor-suite
    trezord
    ledger-live-desktop
    # documents
    onlyoffice-bin_latest
    # video
    vlc
    vlc-bittorrent
  ];
  # udev rules for crypto wallets
  services.udev.packages = with pkgs; [
    ledger-udev-rules
    trezor-udev-rules
  ];
}
