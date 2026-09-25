{ lib, herdr, flox, skygqts, hermenix, ... }:
{
  imports = [
    ./user.nix
    ./macos.nix
    ./nix-substituters.nix
    ./lab-ca.nix
  ];
  options = {
    skyg.rootDir = lib.mkOption {
      type = lib.types.path;
      description = "Top-level path of the nixos-setup repo (set by the flake).";
    };
    skyg.configsDir = lib.mkOption {
      type = lib.types.path;
      description = "Path to the configs directory (set by the flake).";
    };
  };
  config = {
    nixpkgs.overlays = [
      (final: _prev: {
        # colibrì (JustVugg/colibri) — GLM-5.2/OLMoE local inference, see pkgs/colibri.
        colibri = final.callPackage ../../pkgs/colibri { };
        colibri-rocm = final.callPackage ../../pkgs/colibri { backend = "rocm"; };
        # Touchscreen gesture bridge for niri, see pkgs/niri-touchscreen-gestures.
        niri-touchscreen-gestures = final.callPackage ../../pkgs/niri-touchscreen-gestures { };
        # Buzz Desktop AppImage wrapper, see pkgs/buzz-desktop.
        buzz-desktop = final.callPackage ../../pkgs/buzz-desktop { };
        # Superset Desktop AppImage wrapper, see pkgs/superset-desktop.
        superset-desktop = final.callPackage ../../pkgs/superset-desktop { };
        # Delta Editor (Zed Industries) prebuilt tarball, see pkgs/delta-editor.
        delta-editor = final.callPackage ../../pkgs/delta-editor { };

        # herdr (herdrdev/herdr) — see flake.nix input.
        herdr = herdr.packages.${final.stdenv.hostPlatform.system}.default;
        # flox (flox/flox) — see flake.nix input.
        flox_dev = flox.packages.${final.stdenv.hostPlatform.system}.default;
        skygqts = skygqts.packages.${final.stdenv.hostPlatform.system}.default;
        # hermenix CLI (setup/migrate/remote) — see flake.nix input.
        hermenix = hermenix.packages.${final.stdenv.hostPlatform.system}.hermenix;
      })
      (final: prev: {
        pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
          (pyFinal: pyPrev: {
            pipx = pyPrev.pipx.overrideAttrs (_: { doInstallCheck = false; });
          })
        ];
      })
    ];
    # Remote Builder
    nix.buildMachines = [
      {
        hostName = "root@bigbox1.lab.internal";
        systems = [ "x86_64-linux" "aarch64-linux" ];
        protocol = "ssh-ng";
        maxJobs = 25;
        speedFactor = 2;
        supportedFeatures = [
          "nixos-test"
          "benchmark"
          "big-parallel"
          "kvm"
        ];
        mandatoryFeatures = [ ];
      }
      {
        hostName = "root@fwdesk.lab.internal";
        systems = [ "x86_64-linux" "aarch64-linux" ];
        protocol = "ssh-ng";
        maxJobs = 50;
        speedFactor = 4;
        supportedFeatures = [
          "nixos-test"
          "benchmark"
          "big-parallel"
          "kvm"
        ];
        mandatoryFeatures = [ ];
      }
    ];
    nix.distributedBuilds = true;
    # useful when the builder has a faster internet connection than yours
    nix.settings.builders-use-substitutes = true;
  };
}
