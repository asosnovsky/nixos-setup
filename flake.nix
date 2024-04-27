{
  inputs.nixpkgs.url = github:NixOS/nixpkgs/nixos-unstable;
  inputs.home-manager.url = github:nix-community/home-manager;
  inputs.fh.url = "https://flakehub.com/f/DeterminateSystems/fh/*.tar.gz";


  outputs = { self, nixpkgs, home-manager, fh, ... }@attrs:
    let
      user = {
        name = "ari";
        fullName = "Ari Sosnovsky";
        email = "ariel@sosnovsky.ca";
      };
      dataDir = "/mnt/Data";
      systemStateVersion = "23.11";
      homeMangerVersion = "24.04";
      hostName = "fwbook";
    in
    {
      nixosConfigurations.${hostName} = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          hardware-configs/fwbook.nix
          <nixos-hardware/framework/13-inch/7040-amd>
          (import ./modules/os/nix.nix {
            systemStateVersion = systemStateVersion;
          })
          (import ./modules/os/core.nix {
            user = user;
            hostName = hostName;
            firewall = { enable = true; };
          })
          (import ./modules/os/hardware.nix {
            enableFingerPrint = true;
          })
          (import ./modules/os/ssh.nix {
            user = user;
            enableSSHServer = false;
          })
          ./modules/os/services.nix
          ./modules/docker/core.nix
          (import ./modules/user.nix {
            user = user;
          })
          (import ./modules/rootUser.nix {
            hostName = hostName;
          })
          home-manager.nixosModules.default
          fh.packages.x86_64-linux.default
          (import ./modules/optional/home-manager-config.nix {
            homeMangerVersion = homeMangerVersion;
            hostName = hostName;
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
