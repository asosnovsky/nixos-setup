{ config, skyg-secrets, ... }:
{
  age.secrets.portainer-agent-minipc1.file = skyg-secrets.portainer-agent-minipc1;

  skyg.nixos.server.portainer = {
    enable = true;
    mode = "agent";
    agent.edgeKeySecretName = "portainer-agent-minipc1";
  };
}
