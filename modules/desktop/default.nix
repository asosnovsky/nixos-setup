{ user
, enableX11 ? false
, enableGnome ? false
, enableKDE ? false
, enableHypr ? false
, enableWine ? false
, ...
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
}
