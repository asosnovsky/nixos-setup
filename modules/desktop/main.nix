{ user
, enableX11 ? false
, enableGnome ? false
, enableKDE ? false
, enableHypr ? false
}:
{ ... }:
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
    ./hyprland.nix
  ] else [ ]);
}
