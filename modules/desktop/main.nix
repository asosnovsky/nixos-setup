{ user
, enableX11 ? false
, enableGnome ? false
, enableKDE ? false
, enableHypr ? false
}:
{ pkgs, ... }:
{
  imports = [
    ./wayland.nix
  ] ++ (if enableX11 then [
    ./x11.nix
  ] else [ ]) ++ (if enableGnome then [
    ./gnome.nix
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
    firefox
    bitwarden-cli
    zoom-us
    vscode
    betterdiscordctl
    discord
    trezor-suite
    trezord
    ledger-live-desktop
  ];
  # udev rules for crypto wallets
  services.udev.packages = with pkgs; [
    ledger-udev-rules
    trezor-udev-rules
  ];
}
