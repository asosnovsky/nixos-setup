{ config, ... }:
{
  age.secrets.portainer-agent-bigbox1.file = "${config.skyg.rootDir}/secrets/portainer-agent-bigbox1.age";

  skyg.nixos.server.portainer = {
    enable = true;
    mode = "agent";
    agent.edgeKeySecretName = "portainer-agent-bigbox1";
  };
}
