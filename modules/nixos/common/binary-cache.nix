{ config, lib, pkgs, ... }:
let
  cfg = config.skyg.nixos.common.cachePush;
  recv = config.skyg.nixos.common.cacheReceive;
  lab = import ./diagnix/hosts.nix;

  # The hook writes into tmp and moves into queue, which the path unit watches.
  # A push that fails moves its files to retry, for the timer.
  state = "/var/lib/nix-cache-push";
  queue = "${state}/queue";
  retry = "${state}/retry";

  # nix-serve on bigbox2 only serves its own store and can't take uploads, so
  # pushes go over ssh-ng into that store, as the host's root key.
  sshOpts = "-i /etc/ssh/ssh_host_ed25519_key -o StrictHostKeyChecking=yes -o BatchMode=yes -o ConnectTimeout=10";

  drain = pkgs.writeShellScript "nix-cache-push-drain" ''
    set -u
    shopt -s nullglob
    new=(${queue}/*)
    old=(${retry}/*)
    files=("''${new[@]}" "''${old[@]}")
    [ ''${#files[@]} -eq 0 ] && exit 0
    paths=()
    for f in "''${files[@]}"; do
      for p in $(cat "$f"); do
        [ -e "$p" ] && paths+=("$p")
      done
    done
    if [ ''${#paths[@]} -gt 0 ]; then
      if ! NIX_SSHOPTS="${sshOpts}" ${config.nix.package}/bin/nix copy --to "${cfg.url}" "''${paths[@]}"; then
        [ ''${#new[@]} -gt 0 ] && mv "''${new[@]}" ${retry}/
        exit 1
      fi
    fi
    rm -f "''${files[@]}"
  '';
in
{
  options.skyg.nixos.common.cachePush = {
    enable = lib.mkEnableOption "push finished builds to the bigbox2 binary cache";
    url = lib.mkOption {
      type = lib.types.str;
      default = "ssh-ng://nix-ssh@bigbox2.lab.internal";
    };
    host = lib.mkOption {
      type = lib.types.str;
      default = "bigbox2.lab.internal";
      description = "The cache's ssh host, whose host key is pinned from diagnix/hosts.nix.";
    };
  };

  options.skyg.nixos.common.cacheReceive = {
    enable = lib.mkEnableOption "accept pushes into this host's store over ssh-ng (nix-ssh)";
    pushers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "hl-fwdesk" ];
      description = "Hosts in diagnix/hosts.nix whose ssh host key may push.";
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      # The hook only queues the paths: Nix waits for a post-build-hook before it
      # goes on, so copying here held up every build for the whole upload.
      nix.settings.post-build-hook = pkgs.writeShellScript "nix-post-build-hook" ''
        set -u
        if [ -n "''${OUT_PATHS:-}" ]; then
          tmp=$(mktemp -p ${state}/tmp) || exit 0
          echo "$OUT_PATHS" > "$tmp" && mv "$tmp" "${queue}/$(date +%s%N)-$$"
        fi
      '';

      systemd.tmpfiles.rules = map (d: "d ${d} 0700 root root -") [ state "${state}/tmp" queue retry ];

      programs.ssh.knownHosts.nix-cache-push = {
        hostNames = [ cfg.host ];
        publicKey = (lib.findFirst (h: h.address == cfg.host) null (lib.attrValues lab.hosts)).hostKey;
      };

      systemd.services.nix-cache-push = {
        description = "Push queued builds to ${cfg.url}";
        after = [ "network-online.target" ];
        wants = [ "network-online.target" ];
        path = [ config.programs.ssh.package ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = drain;
          Nice = 10;
          IOSchedulingClass = "idle";
        };
      };

      # Runs when the hook queues a build, and every 10 minutes for the retries.
      systemd.paths.nix-cache-push = {
        wantedBy = [ "multi-user.target" ];
        pathConfig.DirectoryNotEmpty = queue;
      };
      systemd.timers.nix-cache-push = {
        wantedBy = [ "timers.target" ];
        timerConfig.OnUnitInactiveSec = "10min";
        timerConfig.OnBootSec = "5min";
      };

      # Manual/backstop push command, available on every host's PATH.
      environment.systemPackages = [
        (pkgs.writeShellScriptBin "push-cache" ''
          set -eu
          if [ "''$#" -eq 0 ]; then
            set -- /run/current-system
          fi
          NIX_SSHOPTS="${sshOpts}" exec nix copy --to "${cfg.url}" "''$@"
        '')
      ];
    })

    (lib.mkIf recv.enable {
      nix.sshServe = {
        enable = true;
        write = true;
        protocol = "ssh-ng";
        # Pushed paths aren't signed; nix-serve signs them with this host's key
        # when it serves them.
        trusted = true;
        keys = map (h: lab.hosts.${h}.hostKey) recv.pushers;
      };
    })
  ];
}
