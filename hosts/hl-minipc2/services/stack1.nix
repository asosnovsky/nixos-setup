{ config, skyg-secrets, ... }:
{
  age.secrets.stack1.file = skyg-secrets.stack1;
  skyg.nixos.common.container-services.stack1 = {
    enable = true;
    autoUpdate.enable = true;
    composeFile = config.age.secrets.stack1.path;
  };
}
