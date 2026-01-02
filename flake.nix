{
  inputs = {
    # Hardware
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    systems.url = "github:nix-systems/default";
    # Nixpkgs
    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/*";
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0";
    nixpkgs-unstable.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";
    # DankShell
    dms = {
      url = "github:AvengeMedia/DankMaterialShell/stable";
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };
    # Flatpak
    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=main";
    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Themes
    stylix = {
      url = "github:nix-community/stylix/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Macos
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Hyprland
    hyprlauncher.url = "github:hyprwm/hyprlauncher";
  };

  outputs =
    { self
    , nixpkgs-unstable
    , determinate
    , nixos-hardware
    , nixpkgs
    , systems
    , home-manager
    , nix-darwin
    , nix-flatpak
    , stylix
    , hyprlauncher
    , dms
    ,
    }:
    let
      # Libs
      lib =
        import modules/lib.nix
          {
            user = {
              name = "ari";
              fullName = "Ari Sosnovsky";
              email = "ariel@sosnovsky.ca";
            };
            inherit
              nixpkgs
              nixpkgs-unstable
              home-manager
              determinate
              nix-darwin
              systems
              nix-flatpak
              stylix
              ;

            specialArgs = {
              inherit
                hyprlauncher
                nixpkgs-unstable
                dms
                ;
            };
          }
      ;
    in
    {
      # Dev Setups
      # -------------
      devShells = lib.eachSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            name = "nixos-setup";
            packages = with pkgs; [
              nixpkgs-fmt
              nixd
              nh
            ];
            shellHook = ''
              export PATH=$PATH:$(pwd)/bin
            '';
          };
        }
      );
      lib = lib;
      formatter = lib.eachSystem (system: nixpkgs.legacyPackages.${system}.nixpkgs-fmt);

      # None-NIXOS LINUX Setups
      # -------------
      # homeConfigurations."${user.name}" = lib.makeHomeManagerUsers {
      #   inherit user homeManagerVersion;
      # };

      # NIXOS LINUX Setups
      # -------------
      nixosConfigurations =
        {
          fwbook = lib.makeNixOs {
            hostName = "fwbook";
            systemStateVersion = "23.11";
            configuration = [
              ./hosts/fwbook.nix
              ./hosts/fwbook.hardware-configuration.nix
              nixos-hardware.nixosModules.framework-13-7040-amd
            ];
          };
          hl-fws1 = lib.makeNixOs {
            hostName = "hl-fws1";
            configuration = [
              ./hosts/hl-fws1.nix
              ./hosts/hl-fws1.hardware-configuration.nix
              nixos-hardware.nixosModules.framework-11th-gen-intel
            ];
          };
          hl-fwdesk = lib.makeNixOs {
            hostName = "hl-fwdesk";
            systemStateVersion = "25.05";
            configuration = [
              ./hosts/hl-fwdesk.nix
              ./hosts/hl-fwdesk.hardware-configuration.nix
              nixos-hardware.nixosModules.framework-desktop-amd-ai-max-300-series
            ];
          };
          hl-bigbox1 = lib.makeNixOs {
            hostName = "hl-bigbox1";
            configuration = [
              ./hosts/hl-bigbox1.nix
              ./hosts/hl-bigbox1.hardware-configuration.nix
            ];
          };
          hl-minipc1 = lib.makeNixOs {
            hostName = "hl-minipc1";
            configuration = [
              ./hosts/hl-minipc1.nix
              ./hosts/hl-minipc1.hardware-configuration.nix
            ];
          };
          hl-minipc2 = lib.makeNixOs {
            hostName = "hl-minipc2";
            configuration = [
              ./hosts/hl-minipc2.nix
              ./hosts/hl-minipc2.hardware-configuration.nix
            ];
          };
          hl-minipc3 = lib.makeNixOs {
            hostName = "hl-minipc3";
            configuration = [
              ./hosts/hl-minipc3.nix
              ./hosts/hl-minipc3.hardware-configuration.nix
            ];
          };
          hl-terra1 = lib.makeNixOs {
            hostName = "hl-terra1";
            configuration = [
              ./hosts/hl-terra1.nix
              ./hosts/hl-terra1.hardware-configuration.nix
            ];
          };
        };
    };
}
