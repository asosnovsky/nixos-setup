{ config, lib, skyg-secrets, ... }:
let
  concurrency = 4;
  runnerNames = map (i: "runner-${toString i}") (lib.range 1 concurrency);
  stateVersion = config.system.stateVersion;
  cache = "/var/cache/github-runners/go";
  credentials = "/run/github-runner-registration";

  # The same numeric identity owns the bind-mounted caches on the host and in every container.
  runnerUser = {
    users.github-runner = {
      uid = 915;
      isSystemUser = true;
      group = "github-runner";
    };
    groups.github-runner.gid = 915;
  };
in
{
  age.secrets.github-runner-token-fws1 = {
    file = skyg-secrets.github-runner-token-fws1;
    path = "${credentials}/token";
    # The containers mount this directory and must see token rotations.
    symlink = false;
    mode = "0400";
  };

  users = runnerUser;
  systemd.tmpfiles.rules = [
    "d ${credentials} 0700 root root -"
    "d ${cache} 0755 root root -"
    "d ${cache}/build 0700 github-runner github-runner -"
    "d ${cache}/mod 0700 github-runner github-runner -"
  ];

  systemd.services = lib.genAttrs (map (name: "container@${name}") runnerNames) (_: {
    serviceConfig = {
      MemoryLow = "4G";
      MemoryMax = "8G";
      CPUQuota = "200%";
    };
  });

  containers = lib.genAttrs runnerNames (name: {
    autoStart = true;
    bindMounts = {
      "${credentials}".isReadOnly = true;
      "/var/cache/go" = {
        hostPath = cache;
        isReadOnly = false;
      };
    };

    config = { pkgs, ... }: {
      system.stateVersion = stateVersion;
      users = runnerUser;
      nix.settings.experimental-features = [ "nix-command" "flakes" ];

      services.github-runners.${name} = {
        enable = true;
        inherit name;
        replace = true;
        url = "https://github.com/SkyG-Org";
        tokenFile = "${credentials}/token";
        user = "github-runner";
        group = "github-runner";
        extraLabels = [ "fws1" "nixos" "go" ];
        extraPackages = [ pkgs.go ];
        extraEnvironment = {
          NIX_REMOTE = "daemon";
          GOCACHE = "/var/cache/go/build";
          GOMODCACHE = "/var/cache/go/mod";
        };
        serviceOverrides.ReadWritePaths = [ "/var/cache/go" ];
      };
    };
  });
}
