{ config, ... }:
{
  age.secrets.stack1.file = ../secrets/stack1.age;
  skyg.nixos.common.container-services.stack1 = {
    enable = true;
    autoUpdate.enable = true;
    composeFile = config.age.secrets.stack1.path;
  };
}
