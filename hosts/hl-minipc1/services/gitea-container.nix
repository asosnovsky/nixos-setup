{ config, lib, pkgs, ... }:
let
  gitea = {
    user = "gitea";
    group = "gitea";
    stateDir = "/var/lib/sosnovsky/gitea";
    sshDir = "/var/lib/sosnovsky/gitea-ssh";
    httpPort = 3000;
    sshPort = 22;
  };
  app = config.skyg.internalNetworkingMap.apps.gitea;
  containerMode = !config.services.gitea.enable;
  uidEnvFile = "/run/gitea-container.env";
in
{
  users.users.gitea = lib.mkIf containerMode {
    isSystemUser = true;
    group = gitea.group;
    home = gitea.stateDir;
    useDefaultShell = true;
  };
  users.groups.gitea = lib.mkIf containerMode { };

  systemd.services.gitea-container-uid = lib.mkIf containerMode {
    description = "Resolve gitea uid/gid for the container";
    wantedBy = [ "container-services-gitea.service" ];
    before = [ "container-services-gitea.service" ];
    path = [ pkgs.coreutils ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      printf 'USER_UID=%s\nUSER_GID=%s\n' \
        "$(id -u ${gitea.user})" "$(id -g ${gitea.user})" > ${uidEnvFile}
    '';
  };

  systemd.tmpfiles.rules = lib.mkIf containerMode [
    "d ${gitea.stateDir} 0750 ${gitea.user} ${gitea.group} -"
    "d ${gitea.sshDir} 0750 ${gitea.user} ${gitea.group} -"
    # Pre-created so the read-only template mount lands in gitea-owned dirs
    # instead of root-owned ones docker would create on demand.
    "d ${gitea.stateDir}/custom 0755 ${gitea.user} ${gitea.group} -"
    "d ${gitea.stateDir}/custom/templates 0755 ${gitea.user} ${gitea.group} -"
  ];

  skyg.nixos.common.container-services.gitea = {
    enable = containerMode;
    autoUpdate.enable = true;
    networks.lan = config.skyg.nixos.common.containers.networks.ipvlanLab.compose;
    services.gitea = {
      # Match the native package so toggling never triggers a DB migration.
      image = "gitea/gitea:${pkgs.gitea.version}";
      networks.lan.ipv4_address = app.ip;
      environmentFiles = [ uidEnvFile ];
      environment = {
        GITEA_WORK_DIR = gitea.stateDir;
        GITEA_CUSTOM = "${gitea.stateDir}/custom";
        # The image renames its `git` user to $USER, so this makes RUN_USER,
        # sshd AllowUsers and the container's runtime user all `gitea`.
        USER = gitea.user;
        HOME = "/data/git";
        GITEA__server__APP_DATA_PATH = "${gitea.stateDir}/data";
        GITEA__server__SSH_ROOT_PATH = "/data/git/.ssh";
        GITEA__repository__ROOT = "${gitea.stateDir}/repositories";
        GITEA__database__PATH = "${gitea.stateDir}/data/gitea.db";
        GITEA__log__ROOT_PATH = "${gitea.stateDir}/log";
        GITEA__server__START_SSH_SERVER = "false";
        GITEA__server__SSH_PORT = toString gitea.sshPort;
        GITEA__server__SSH_USER = gitea.user;
        GITEA__server__DOMAIN = app.effectiveDns;
        GITEA__server__HTTP_PORT = toString gitea.httpPort;
        GITEA__server__ROOT_URL = "http://${app.effectiveDns}:${toString gitea.httpPort}/";
        GITEA__service__DISABLE_REGISTRATION = "true";
        GITEA__migrations__ALLOW_LOCALNETWORKS = "true";
        GITEA__migrations__ALLOWED_DOMAINS = "gitea.skyg.ca,github.com";
      };
      volumes = [
        "${gitea.stateDir}:${gitea.stateDir}"
        "${gitea.sshDir}:/data"
      ];
      # Custom landing page, mounted read-only over GITEA_CUSTOM/templates.
      files."${gitea.stateDir}/custom/templates/home.tmpl" =
        builtins.readFile ./gitea-home.tmpl;
    };
  };
}
