{ config, ... }:
let
  apps = config.skyg.internalNetworkingMap.apps;
  ports = {
    ollama = 11434;
    ds4 = 8000;
    tracker = 1984;
  };
in
{
  skyg.nixos.server.robotnix = {
    enable = true;
    externalInterface = "enp191s0";

    # Every robot gets this tier. Same holes as the Hermes VM.
    access.shared = {
      internet = "all";
      hostAccess = [
        { port = ports.ollama; }
        { port = ports.tracker; }
      ];
      lanAccess = [ ];
    };

    robots.genix = {
      id = 1;
      address = apps.genix.ip;
      cpus = { min = 1; max = 4; };
      memory = { min = "8G"; max = "16G"; };
      disk = { rootSize = "100G"; homeSize = "60G"; };
      seed.configuration = ./robotnix/genix.nix;
      access = { };
      git = {
        enable = true;
        remoteUrl = "gitea@gitea.app.internal:Hermenix/genix.git";
      };
    };
  };
}
