{ ... }:
{
  imports = [
    ./user.nix
    ./macos.nix
    ./nix-substituters.nix
  ];
  config = {
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
