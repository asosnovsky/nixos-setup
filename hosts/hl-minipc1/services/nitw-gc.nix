{ config, skyg-secrets, ... }:
{
  # Secret app. The whole container definition lives in the agenix secret
  # (see secrets/nitw-gc.age); this file only points at it.
  age.secrets.nitw-gc.file = skyg-secrets.nitw-gc;
  age.secrets.nitw-gc-home.file = skyg-secrets.nitw-gc-home;

  skyg.nixos.common.container-services.nitw-gc = {
    enable = true;
    autoUpdate.enable = true;
    composeFile = config.age.secrets.nitw-gc.path;
    networks.lan = config.skyg.nixos.common.containers.networks.ipvlanLab.compose;
  };
}
