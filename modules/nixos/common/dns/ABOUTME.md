# Boot-time DNS check

Six hosts opt into this module, including hl-bigbox1. It was introduced after the reported 79-minute DNS outage on that host on 2026-11-16. The incident account suspected journal corruption after an unclean shutdown. This module keeps logs for investigation.

## Configuration

```nix
skyg.nixos.common.dns.enable = true;
```

| Option under `skyg.nixos.common.dns` | Default | Purpose |
| --- | --- | --- |
| `enable` | `false` | Enable resolved, persistent journal storage, and the boot check. |
| `bootCheckName` | `"portainer.app.internal"` | Name expected to resolve to an IPv4 address on this host's network. |
| `bootCheckRetries` | `5` | Maximum lookup attempts, spaced one second apart after each failure. |
| `watchdogEnabled` | `true` | Configure systemd to feed a hardware watchdog when available. |
| `watchdogTimeout` | `30` | Runtime watchdog timeout in seconds if systemd stops feeding it. |

## Boot behavior

After network-online.target and systemd-resolved start, dns-boot-check queries the host stub at 127.0.0.53 for the configured name. A returned IPv4 address passes the check. A cached answer can pass. Choose a record available independently of containers starting on the same host.

The container service groups are ordered after the check. An exhausted retry budget leaves the diagnostic unit failed and allows the groups to start. A DNS failure alone does not trigger a reboot. The probe runs once per boot and can be rerun manually.

The journal persists across boots. The module sets a 500M persistent storage limit, a 100M runtime limit and a 30-day retention limit. Host configuration can override these limits.

## Investigating a failure

```bash
journalctl -b -u dns-boot-check -u systemd-resolved
resolvectl status
dig +time=2 +tries=1 @127.0.0.53 portainer.app.internal A
```

Use the configured name if the host overrides the default. Check the DNS status and answer section, and compare the upstream servers and routing domains in `resolvectl status` with the intended network. After correcting the problem, run `systemctl restart dns-boot-check` and check `systemctl status dns-boot-check`. For a failure on the previous boot, use `journalctl -b -1` with the same unit filters.
