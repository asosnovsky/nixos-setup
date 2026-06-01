{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.skyg.server.dns.certbot;
in
{
  options = {
    skyg.server.dns.certbot = {
      enable = mkEnableOption "Let's Encrypt certificate management with certbot for DNS domains";

      publicDomains = mkOption {
        description = "List of public domains for which to obtain Let's Encrypt certificates";
        type = types.listOf types.str;
        default = [ ];
      };

      email = mkOption {
        description = "Email address for Let's Encrypt account registration";
        type = types.str;
        example = "admin@example.com";
      };

      testMode = mkOption {
        description = "Use certbot in test mode (dry-run) for development/testing";
        type = types.bool;
        default = false;
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.certbot pkgs.certbot-nginx ];

    # Set up systemd service for certificate renewal
    systemd.services.certbot-renew = {
      description = "Renew Let's Encrypt certificates";
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        ExecStart =
          if cfg.testMode then
            "${pkgs.certbot}/bin/certbot renew --dry-run --nginx"
          else
            "${pkgs.certbot}/bin/certbot renew --nginx";
      };
    };

    # Set up systemd timer for certificate renewal
    systemd.timers.certbot-renew = {
      description = "Daily renewal of Let's Encrypt certificates";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
    };

    # Enable the renewal timer
    systemd.timers.certbot-renew.enable = true;

    # Configure nginx with virtual hosts for public domains
    services.nginx = {
      enable = true;
    };

    # Create a simple certbot command that can be run manually
    environment.shellAliases = {
      "certbot-get-certs" =
        "${pkgs.certbot}/bin/certbot certonly --nginx --non-interactive --agree-tos --email ${cfg.email} --expand ${concatMapStrings (domain: " --domains ${domain}") cfg.publicDomains}";
    };
  };
}
