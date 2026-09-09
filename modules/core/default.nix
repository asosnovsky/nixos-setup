{ lib, herdr, flox, claude-desktop, ... }:
{
  imports = [
    ./user.nix
    ./macos.nix
    ./nix-substituters.nix
  ];
  options = {
    skyg.rootDir = lib.mkOption {
      type = lib.types.path;
      description = "Top-level path of the nixos-setup repo (set by the flake).";
    };
  };
  config = {
    nixpkgs.overlays = [
      (final: _prev: {
        # xAI Grok CLI — prebuilt binary, see pkgs/grok-cli.
        grok-cli = final.callPackage ../../pkgs/grok-cli { };
        # DwarfStar (antirez/ds4) inference engine, see pkgs/ds4.
        # Backend-parameterized: cpu (default), rocm (Strix Halo), cuda.
        ds4 = final.callPackage ../../pkgs/ds4 { };
        ds4-rocm = final.callPackage ../../pkgs/ds4 { backend = "rocm"; };
        ds4-cuda = final.callPackage ../../pkgs/ds4 { backend = "cuda"; };
        # colibrì (JustVugg/colibri) — GLM-5.2/OLMoE local inference, see pkgs/colibri.
        # Backend-parameterized: cpu (default), rocm (Strix Halo).
        colibri = final.callPackage ../../pkgs/colibri { };
        colibri-rocm = final.callPackage ../../pkgs/colibri { backend = "rocm"; };
        # Touchscreen gesture bridge for niri, see pkgs/niri-touchscreen-gestures.
        niri-touchscreen-gestures = final.callPackage ../../pkgs/niri-touchscreen-gestures { };
        # Buzz Desktop AppImage wrapper, see pkgs/buzz-desktop.
        buzz-desktop = final.callPackage ../../pkgs/buzz-desktop { };
        # Claude Desktop (Linux), see pkgs/claude-desktop.
        claude-desktop = claude-desktop.packages.${final.system}.default;
        # herdr (herdrdev/herdr) — see flake.nix input.
        herdr = herdr.packages.${final.system}.default;
        # flox (flox/flox) — see flake.nix input.
        flox_dev = flox.packages.${final.system}.default;
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
    # optional, useful when the builder has a faster internet connection than yours
    nix.extraOptions = ''
      	    builders-use-substitutes = true
      	  '';
  };
}
