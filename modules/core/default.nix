{ ... }:
{
  imports = [
    ./user.nix
    ./macos.nix
    ./nix-substituters.nix
  ];
  config = {
    # Workaround: pipx 1.8.0 test suite fails in nixpkgs 26.05 due to a whitespace
    # normalization regression in PEP 508 URL specifiers (space before @ in URLs).
    # Must use pythonPackagesExtensions to patch the python3Packages.pipx that
    # the build system actually uses, not just the top-level pkgs.pipx wrapper.
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
        # ollama pinned ahead of nixpkgs (0.32.14 vs the 0.32.7 in stable/unstable).
        # See pkgs/ollama for hashing instructions.
        ollama = final.callPackage ../../pkgs/ollama { };
        ollama-rocm = final.callPackage ../../pkgs/ollama { acceleration = "rocm"; };
        ollama-vulkan = final.callPackage ../../pkgs/ollama { acceleration = "vulkan"; };
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
        system = "x86_64-linux";
        protocol = "ssh-ng";
        maxJobs = 2;
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
        hostName = "root@hl-fwdesk.lab.internal";
        system = "x86_64-linux";
        protocol = "ssh-ng";
        maxJobs = 4;
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
