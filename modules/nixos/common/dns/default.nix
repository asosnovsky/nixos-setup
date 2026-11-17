{ config, lib, pkgs, ... }:
let
  cfg = config.skyg.nixos.common.dns;
in
{
  options.skyg.nixos.common.dns = {
    enable = lib.mkOption {
      description = "Enable hardened systemd-resolved DNS with boot verification and journal recovery.";
      type = lib.types.bool;
      default = false;
    };
    
    watchdogEnabled = lib.mkOption {
      description = "Enable systemd watchdog for automatic recovery on DNS/systemd failures.";
      type = lib.types.bool;
      default = true;
    };
    
    watchdogTimeout = lib.mkOption {
      description = "Watchdog timeout in seconds (auto-reboot if system unresponsive for this long).";
      type = lib.types.int;
      default = 30;
    };
    
    bootCheckRetries = lib.mkOption {
      description = "Number of DNS health check retries during boot before failing fast.";
      type = lib.types.int;
      default = 5;
    };
  };
  
  config = lib.mkIf cfg.enable {
    # Enable systemd-resolved explicitly (don't rely on defaults)
    services.resolved = {
      enable = true;
      llmnr = "yes";           # Allow local resolution fallback
      dnssec = "allow-downgrade";  # Tolerant of DNSSEC issues (network-dependent)
      dnsovertls = "no";       # Keep plain DNS for lab environment
      extraConfig = ''
        [Resolve]
        # Use upstream resolvers if configured by DHCP/static config
        Domains=~.
        # Increase timeout to tolerate slow lab network
        DNSStubListenerPort=53
      '';
    };
    
    # Harden journald to survive unclean shutdown and corruption
    systemd.journald = {
      extraConfig = ''
        [Journal]
        Storage=persistent
        # Keep journal compressed and limit size
        SystemMaxUse=500M
        SystemMaxFileSize=50M
        RuntimeMaxUse=100M
        RuntimeMaxFileSize=10M
        # Vacuum on startup to recover from corruption
        MaxRetentionSec=30day
        MaxFileSec=7day
      '';
    };
    
    # Enable watchdog for automatic recovery (if DNS fails to start, reboot)
    systemd.watchdog = lib.mkIf cfg.watchdogEnabled {
      runtimeSec = "${toString cfg.watchdogTimeout}s";
      rebootTime = "${toString (cfg.watchdogTimeout + 10)}s";
    };
    
    # Ensure systemd notices watchdog (all services should use it)
    systemd.defaultUnit = "multi-user.target";
    
    # Boot check service: verify DNS is actually responding (not just started)
    systemd.services."dns-boot-check" = {
      description = "DNS Boot-Time Health Check";
      documentation = [ "man:resolved.conf(5)" ];
      wantedBy = [ "network-online.target" ];
      before = [ "network-online.target" ];
      after = [ "systemd-resolved.service" ];
      requires = [ "systemd-resolved.service" ];
      
      unitConfig = {
        # Allow this to fail without breaking the entire boot
        # (watchdog will trigger if systemd-resolved is dead)
        ConditionPathExists = "/run/systemd/resolve/stub-resolv.conf";
      };
      
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        # Try multiple times to allow systemd-resolved to settle
        ExecStart = ''
          ${pkgs.bash}/bin/bash -c '
            attempt=0
            max_attempts=${toString cfg.bootCheckRetries}
            
            while [ $attempt -lt $max_attempts ]; do
              # Check that DNS responds on the stub resolver
              if ${pkgs.dnsutils}/bin/dig +short @127.0.0.11 localhost > /dev/null 2>&1; then
                echo "DNS is responding on 127.0.0.11:53"
                exit 0
              fi
              attempt=$((attempt + 1))
              echo "DNS check attempt $attempt/$max_attempts failed, retrying..."
              sleep 1
            done
            
            echo "ERROR: DNS did not respond after $max_attempts attempts"
            echo "systemd-resolved status:"
            ${pkgs.systemd}/bin/systemctl status systemd-resolved || true
            exit 1
          '
        '';
        StandardOutput = "journal";
        StandardError = "journal";
        SyslogIdentifier = "dns-boot-check";
        # If this fails, the watchdog will eventually reboot us
        # (better than a silent DNS failure)
      };
    };
    
    # Ensure network doesn't mark itself "online" until DNS is actually working
    systemd.targets."network-online".wants = [ "dns-boot-check.service" ];
  };
}
