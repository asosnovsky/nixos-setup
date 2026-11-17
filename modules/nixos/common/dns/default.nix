{ config, lib, pkgs, ... }:
let
  cfg = config.skyg.nixos.common.dns;
in
{
  options.skyg.nixos.common.dns = {
    enable = lib.mkEnableOption "systemd-resolved with a boot-time DNS diagnostic";

    bootCheckName = lib.mkOption {
      type = lib.types.strMatching "[a-zA-Z0-9][a-zA-Z0-9.-]*";
      default = "portainer.app.internal";
      description = "Internal DNS name expected to have an IPv4 address at boot.";
    };

    bootCheckRetries = lib.mkOption {
      type = lib.types.ints.positive;
      default = 5;
      description = "Maximum number of DNS lookup attempts at boot.";
    };

    watchdogEnabled = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable the system manager's hardware watchdog.";
    };

    watchdogTimeout = lib.mkOption {
      type = lib.types.ints.positive;
      default = 30;
      description = "Runtime hardware watchdog timeout in seconds.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.resolved = {
      enable = true;
      settings.Resolve = {
        LLMNR = "yes";
        DNSSEC = "allow-downgrade";
        DNSOverTLS = false;
        Domains = config.networking.search ++ [ "~." ];
      };
    };

    services.journald = {
      storage = "persistent";
      extraConfig = lib.mkBefore ''
        SystemMaxUse=500M
        SystemMaxFileSize=50M
        RuntimeMaxUse=100M
        RuntimeMaxFileSize=10M
        MaxRetentionSec=30day
        MaxFileSec=7day
      '';
    };

    systemd.settings.Manager = lib.mkIf cfg.watchdogEnabled {
      RuntimeWatchdogSec = "${toString cfg.watchdogTimeout}s";
      RebootWatchdogSec = "${toString (cfg.watchdogTimeout + 10)}s";
    };

    systemd.services.dns-boot-check = {
      description = "Check internal DNS resolution at boot";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" "systemd-resolved.service" ];
      requires = [ "systemd-resolved.service" ];
      path = [ pkgs.dnsutils pkgs.gnugrep pkgs.coreutils ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        name=${lib.escapeShellArg cfg.bootCheckName}
        attempts=${toString cfg.bootCheckRetries}
        for ((attempt=1; attempt<=attempts; attempt++)); do
          if answer=$(dig +short +time=2 +tries=1 @127.0.0.53 -q "$name" -t A) &&
             grep -Eq '^([0-9]{1,3}\.){3}[0-9]{1,3}$' <<< "$answer"; then
            echo "$name resolved through 127.0.0.53"
            exit 0
          fi
          echo "No IPv4 answer for $name (attempt $attempt/$attempts)" >&2
          if ((attempt < attempts)); then sleep 1; fi
        done
        exit 1
      '';
    };
  };
}
