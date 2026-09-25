{ config, ... }:
{
  age.secrets.portainer-agent-minipc1.file = "${config.skyg.rootDir}/secrets/portainer-agent-minipc1.age";

  skyg.nixos.server.portainer = {
    enable = true;
    mode = "agent";
    agent.edgeKeySecretName = "portainer-agent-minipc1";
  };
}
