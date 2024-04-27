{
  inputs.nixpkgs.url = github:NixOS/nixpkgs/nixos-unstable;
  inputs.home-manager.url = github:nix-community/home-manager;


  outputs = { self, nixpkgs, ... }@attrs:
    let
      user = {
        name = "ari";
        fullName = "Ari Sosnovsky";
        email = "ariel@sosnovsky.ca";
      };
      dataDir = "/mnt/Data";
    in
    {
      nixosConfigurations.default = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          /etc/nixos/cachix.nix
          <nixos-hardware/framework/13-inch/7040-amd>
          (import /home/ari/nixos-setup/main.nix {
            enableFingerPrint = true;
            hostName = "fwbook";
            user = user;
          })
          /home/ari/nixos-setup/modules/optional/amd-packages.nix
          /home/ari/nixos-setup/modules/optional/gnome.nix
          (import /home/ari/nixos-setup/modules/optional/hyprland.nix {
            user = user;
          })
          {
            hardware.framework.amd-7040.preventWakeOnAC = true;
            services.fwupd.enable = true;
            fileSystems."${dataDir}" = {
              device = "/dev/sda1";
              fsType = "ext4";
              options = [
                "users"
                "nofail"
              ];
            };
          }
        ];
      };
    };
}
