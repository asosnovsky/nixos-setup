{ config, lib, ... }:

with lib;

let
  cfg = config.skyg.server.acme;
in
{
  # Let's Encrypt certificates via DNS-01 (NixOS security.acme / lego).
  # Proves domain ownership through DNS records at the provider — nothing
  # needs to be reachable from the internet.
  options.skyg.server.acme = {
    enable = mkEnableOption "Let's Encrypt certificates via DNS-01";

    email = mkOption {
      type = types.str;
      default = "admin@sosnovsky.ca";
      description = "Contact email for the Let's Encrypt account (expiry notices).";
    };

    dnsProvider = mkOption {
      type = types.str;
      default = "cloudflare";
      description = "lego DNS provider used to prove ownership (see lego docs for names).";
    };

    credentialsFile = mkOption {
      type = types.path;
      description = ''
        File with the DNS provider's API credentials in lego's env-var format
        (e.g. CLOUDFLARE_DNS_API_TOKEN=... for cloudflare). Point at an agenix
        secret so the token never enters the Nix store.
      '';
    };

    certs = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          extraDomains = mkOption {
            type = types.listOf types.str;
            default = [ ];
            description = "Extra names covered by the same certificate (SANs).";
          };
          reloadServices = mkOption {
            type = types.listOf types.str;
            default = [ ];
            description = "Native systemd services reloaded after each renewal.";
          };
          postRun = mkOption {
            type = types.str;
            default = "";
            description = "Shell command run after each renewal (e.g. restart a container).";
          };
          orderBefore = mkOption {
            type = types.listOf types.str;
            default = [ ];
            description = ''
              systemd.services attribute names (without the .service suffix)
              that must start only after this cert exists (first boot).
            '';
          };
        };
      });
      default = { };
      description = "Certificates to issue; the attribute name is the primary domain.";
    };
  };

  config = mkIf cfg.enable {
    security.acme = {
      acceptTerms = true;
      defaults.email = cfg.email;
      certs = mapAttrs
        (domain: certCfg: {
          inherit (cfg) dnsProvider;
          environmentFile = cfg.credentialsFile;
          extraDomainNames = certCfg.extraDomains;
          reloadServices = certCfg.reloadServices;
          postRun = certCfg.postRun;
        })
        cfg.certs;
    };

    # First-boot ordering: consumers start only after the cert exists.
    systemd.services = mkMerge (flatten (
      mapAttrsToList
        (domain: certCfg:
          map
            (unit: {
              ${unit} = {
                after = [ "acme-${domain}.service" ];
                wants = [ "acme-${domain}.service" ];
              };
            })
            certCfg.orderBefore)
        cfg.certs
    ));
  };
}
