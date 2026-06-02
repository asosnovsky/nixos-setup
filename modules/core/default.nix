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
        maxJobs = 1;
        speedFactor = 2;
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
