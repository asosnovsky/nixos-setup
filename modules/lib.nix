{ nixpkgs
, nixpkgs-unstable
, user
, determinate
, home-manager
, nix-darwin
, systems
, nix-flatpak
, stylix
, agenix
, specialArgs
}:
let
  skygUtils = import ./skyg-utils.nix {
    pkgs = allPkgs.x86_64-linux;
    lib = nixpkgs.lib;
  };
  eachSystem = nixpkgs.lib.genAttrs (import systems);
  allPkgs = eachSystem (
    system:
    import nixpkgs {
      inherit system;
      config = {
        allowUnfree = true;
      };
      overlays = [
        (final: _prev: {
          grok-cli = final.callPackage ../pkgs/grok-cli { };
          # CPU variant only here (buildable on any system); the GPU variants
          # need their toolchains and are wired in modules/core/default.nix.
          ds4 = final.callPackage ../pkgs/ds4 { };
          niri-touchscreen-gestures = final.callPackage ../pkgs/niri-touchscreen-gestures { };
        })
      ];
    }
  );
  # Build nixosUtils with access to pkgs and lib
  osModules = [
    determinate.nixosModules.default
    stylix.nixosModules.stylix
    home-manager.nixosModules.default
    nix-flatpak.nixosModules.nix-flatpak
    agenix.nixosModules.default
    specialArgs.dms.nixosModules.dank-material-shell
    specialArgs.dms.nixosModules.greeter
    specialArgs.nix-index-database.nixosModules.nix-index
    specialArgs.hermes-agent.nixosModules.default
    { programs.nix-index-database.comma.enable = true; }
  ];

  # Shared function to create home-manager user configuration
  makeHomeConfig = {}: import ./home { };
in
{
  eachSystem = eachSystem;
  pkgs = allPkgs;

  # Standalone home-manager configuration (for non-NixOS systems)
  makeHomeManagerUsers =
    { modules ? [ ]
    , userConfig ? user
    , system ? "x86_64-linux"
    }:
    let
      hm = makeHomeConfig { };
      pkgs = allPkgs.${system};
    in
    home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = specialArgs // {
        inherit system skygUtils;
        user = userConfig;
        unstablePkgs = nixpkgs-unstable.legacyPackages.${system};
      };
      modules = [
        {
          # Convert the attribute set to a proper home-manager module
          config = (hm.makeCommonUser userConfig) { inherit pkgs; };
        }
        stylix.homeModules.stylix
        specialArgs.nix-index-database.homeModules.nix-index
        { programs.nix-index-database.comma.enable = true; }
      ] ++ modules;
    };

  makeNixOs =
    { system ? "x86_64-linux"
    , hostName
    , systemStateVersion ? "26.05"
    , configuration ? [ ]
    }: nixpkgs.lib.nixosSystem {
      specialArgs = specialArgs // {
        inherit system skygUtils user;
        unstablePkgs = nixpkgs-unstable.legacyPackages.${system};
      };
      inherit system;
      modules = osModules ++ [
        (import ./main.nix {
          inherit
            user
            hostName
            systemStateVersion;
        })
      ] ++ configuration;
    };

  makeIso =
    { system ? "x86_64-linux"
    , hostName
    , systemStateVersion ? "26.05"
    , homeManagerVersion ? "26.05"
    , configuration ? [ ]
    }: nixpkgs.lib.nixosSystem {
      specialArgs = specialArgs // {
        inherit system skygUtils user;
        unstablePkgs = nixpkgs-unstable.legacyPackages.${system};
      };
      inherit system;
      modules = osModules ++ [
        "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
        (import ./main.nix {
          inherit
            user
            hostName
            systemStateVersion
            homeManagerVersion
            ;
        })
      ] ++ configuration;
    };

  makeDarwinModule =
    { system ? "x86_64-darwin"
    , user
    , homeManagerVersion ? "26.05"
    , systemStateVersion ? "26.05"
    , hostName
    , configuration ? [ ]
    }:
    nix-darwin.lib.darwinSystem {
      inherit system;
      specialArgs = specialArgs // {
        inherit system skygUtils user;
        unstablePkgs = nixpkgs-unstable.legacyPackages.${system};
      };
      modules = [
        determinate.darwinModules.default
        home-manager.darwinModules.home-manager
        stylix.darwinModules.stylix
        specialArgs.nix-index-database.darwinModules.nix-index
        { programs.nix-index-database.comma.enable = true; }
        (import ./macos.nix {
          user = user;
          system = system;
        })
        (import ./main.nix {
          inherit
            user
            homeManagerVersion
            hostName
            systemStateVersion;
        })
      ] ++ configuration;
    };
}
