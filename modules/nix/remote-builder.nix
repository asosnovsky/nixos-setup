{ user }:
{ config, lib, ... }:
with lib;
let cfg = config.homelab.nix.remote-builder;
in {
  options = {
    homelab.nix.remote-builder = {
      enable = mkEnableOption
        "Enable Remote Local Builders";
    };
  };
  config = mkIf cfg.enable {
    nix.buildMachines = [{
      hostName = "bigbox1.lab.internal";
      sshUser = user.name;
      system = "x86_64-linux";
      protocol = "ssh-ng";
      maxJobs = 4;
      speedFactor = 4;
      supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
      mandatoryFeatures = [ ];
    }];
    nix.distributedBuilds = true;
    nix.extraOptions = ''
      builders-use-substitutes = true
    '';
  };
}
