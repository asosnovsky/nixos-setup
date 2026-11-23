{ nixpkgs
, nixpkgs-unstable
, user
, rootDir
, configsDir
, determinate
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
    rootDir = rootDir;
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
          colibri = final.callPackage ../pkgs/colibri { };
          niri-touchscreen-gestures = final.callPackage ../pkgs/niri-touchscreen-gestures { };
          buzz-desktop = final.callPackage ../pkgs/buzz-desktop { };
          buzz-cli = final.callPackage ../pkgs/buzz-cli { };
          delta-editor = final.callPackage ../pkgs/delta-editor { };
        })
      ];
    }
  );
  # Build nixosUtils with access to pkgs and lib
  osModules = [
    determinate.nixosModules.default
    stylix.nixosModules.stylix
    nix-flatpak.nixosModules.nix-flatpak
    agenix.nixosModules.default
    specialArgs.dms.nixosModules.dank-material-shell
    specialArgs.dank-greeter.nixosModules.default
    specialArgs.nix-index-database.nixosModules.nix-index
    specialArgs.hermes-agent.nixosModules.default
    specialArgs.hhstream.nixosModules.default
    specialArgs.skyg-linux-tracker.nixosModules.default
    { programs.nix-index-database.comma.enable = true; }
  ];
  allUnstablePkgs = eachSystem (
    system:
    import nixpkgs-unstable {
      inherit system;
      config = {
        allowUnfree = true;
      };
    }
  );

in
{
  eachSystem = eachSystem;
  pkgs = allPkgs;

  makeNixOs =
    { system ? "x86_64-linux"
    , hostName
    , systemStateVersion ? "26.05"
    , configuration ? [ ]
    }: nixpkgs.lib.nixosSystem {
      specialArgs = specialArgs // {
        inherit system skygUtils user;
        unstablePkgs = allUnstablePkgs.${system};
        myPkgs = specialArgs.my-nixpkgs.legacyPackages.${system};
      };
      inherit system;
      modules = osModules ++ [
        (import ./main.nix {
          inherit
            user
            rootDir
            configsDir
            hostName
            systemStateVersion;
        })
      ] ++ configuration;
    };

  makeIso =
    { system ? "x86_64-linux"
    , hostName
    , systemStateVersion ? "26.05"
    , configuration ? [ ]
    }: nixpkgs.lib.nixosSystem {
      specialArgs = specialArgs // {
        inherit system skygUtils user;
        unstablePkgs = allUnstablePkgs.${system};
      };
      inherit system;
      modules = osModules ++ [
        "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
        (import ./main.nix {
          inherit
            user
            rootDir
            configsDir
            hostName
            systemStateVersion
            ;
        })
      ] ++ configuration;
    };

  makeSdImage =
    { system ? "aarch64-linux"
    , hostName
    , systemStateVersion ? "26.05"
    , configuration ? [ ]
    }: nixpkgs.lib.nixosSystem {
      specialArgs = specialArgs // {
        inherit system skygUtils user;
        unstablePkgs = allUnstablePkgs.${system};
      };
      inherit system;
      modules = osModules ++ [
        "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
        (import ./main.nix {
          inherit
            user
            rootDir
            configsDir
            hostName
            systemStateVersion
            ;
        })
      ] ++ configuration;
    };
}
