{ config, ... }:
{
  age.secrets.stack2.file = "${config.skyg.rootDir}/secrets/stack2.age";
  skyg.nixos.common.container-services.stack2 = {
    enable = true;
    autoUpdate.enable = true;
    composeFile = config.age.secrets.stack2.path;
  };
}
