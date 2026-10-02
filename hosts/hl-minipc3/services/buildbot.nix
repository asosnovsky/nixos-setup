{ config, lib, pkgs, skyg-secrets, ... }:
let
  # Internal-only: reachable on the LAN, no nginx/TLS. The host's own
  # lab.internal name already resolves via the router.
  domain = "minipc3.lab.internal";
  port = 8010;

  # Worker credentials are assembled at runtime from the per-host password
  # secrets (secret values aren't readable at eval time), so there is no
  # combined workers-JSON secret.
  workers = [
    {
      name = "hl-minipc3";
      cores = 2;
      passwordFile = config.age.secrets.buildbot-worker-password-minipc3.path;
    }
    {
      name = "hl-fwdesk";
      cores = 4;
      passwordFile = config.age.secrets.buildbot-worker-password-fwdesk.path;
    }
  ];
  workersFile = "/run/buildbot-workers.json";
  # jq identifiers can't contain '-', so sanitize the worker name for --arg.
  jqVar = w: "pw_" + lib.replaceStrings [ "-" ] [ "_" ] w.name;
  jqArgs = lib.concatMapStrings (w: "--arg ${jqVar w} \"$(cat ${w.passwordFile})\" ") workers;
  jqFilter = "["
    + lib.concatMapStringsSep ","
    (w:
      "{name:${builtins.toJSON w.name},pass:$${jqVar w},cores:${toString w.cores}}")
    workers
    + "]";
in
{
  age.secrets.buildbot-worker-password-minipc3.file = skyg-secrets.buildbot-worker-password-minipc3;
  age.secrets.buildbot-worker-password-fwdesk.file = skyg-secrets.buildbot-worker-password-fwdesk;
  age.secrets.buildbot-gitea-token.file = skyg-secrets.buildbot-gitea-token;
  age.secrets.buildbot-gitea-webhook-secret.file = skyg-secrets.buildbot-gitea-webhook-secret;
  age.secrets.buildbot-gitea-oauth-secret.file = skyg-secrets.buildbot-gitea-oauth-secret;

  services.buildbot-master.port = port;

  services.buildbot-nix.master = {
    enable = true;
    domain = domain;
    enableNginx = false;
    useHTTPS = false;
    admins = [ "ari" ];
    workersFile = workersFile;
    authBackend = "gitea";
    gitea = {
      enable = true;
      instanceUrl = "http://gitea.app.internal:3000";
      tokenFile = config.age.secrets.buildbot-gitea-token.path;
      webhookSecretFile = config.age.secrets.buildbot-gitea-webhook-secret.path;
      # Client ID of the Gitea OAuth2 app (public value; secret lives in the age file).
      oauthId = "buildbot-nix";
      oauthSecretFile = config.age.secrets.buildbot-gitea-oauth-secret.path;
      topic = "build-with-buildbot";
    };
  };

  # The module derives buildbotUrl without the port; keep links/webhooks correct.
  services.buildbot-master.buildbotUrl = lib.mkForce "http://${domain}:${toString port}/";

  # Assemble the workers JSON from the per-host password secrets at start.
  systemd.services.buildbot-workers-file = {
    description = "Assemble buildbot-nix workers JSON from agenix secrets";
    before = [ "buildbot-master.service" ];
    serviceConfig = {
      Type = "oneshot";
      UMask = "0077";
    };
    script = ''
      ${pkgs.jq}/bin/jq -n ${jqArgs} '${jqFilter}' > ${workersFile}
    '';
  };
  systemd.services.buildbot-master = {
    wants = [ "buildbot-workers-file.service" ];
    after = [ "buildbot-workers-file.service" ];
  };

  services.buildbot-nix.worker = {
    enable = true;
    name = "hl-minipc3";
    workers = 2;
    masterUrl = "tcp:host=${domain}:port=9989";
    workerPasswordFile = config.age.secrets.buildbot-worker-password-minipc3.path;
  };
}
