{ config, skyg-secrets, ... }:
{
  age.secrets.stack2.file = skyg-secrets.stack2;
  skyg.nixos.common.container-services.stack2 = {
    enable = true;
    autoUpdate.enable = true;
    composeFile = config.age.secrets.stack2.path;
  };
}
