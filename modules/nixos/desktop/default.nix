{ ... }:
{
  imports = [
    ./kde.nix
    ./hyprland.nix
    ./wayland.nix
    ./x11.nix
    ./packages.nix
  ];

  services.displayManager.sddm.enable = true;
  services.displayManager.sddm.wayland.enable = true;
}
