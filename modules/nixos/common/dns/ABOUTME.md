# modules/nixos/common/dns/

Hardened DNS initialization, boot-time verification, and journald recovery to prevent systemd-resolved failures during boot.

## Motivation

**Outage root cause (2026-11-16, bigbox1, 79 minutes):**
- Unclean shutdown corrupted systemd journal
- systemd couldn't load org.freedesktop.resolve1 D-Bus service file
- systemd-resolved never started
- All DNS queries failed ("server misbehaving")
- Containers failed to start (Jellyfin, etc.)
- Health checks timed out (couldn't resolve hostnames)
- **No automatic recovery** (manual intervention required)

**Solution:** Harden DNS initialization with explicit configuration, boot-time verification, and automatic recovery via systemd watchdog.

## Options

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `skyg.nixos.common.dns.enable` | bool | `true` | Enable hardened DNS with boot check and journal recovery. |
| `skyg.nixos.common.dns.watchdogEnabled` | bool | `true` | Enable systemd watchdog for auto-recovery. |
| `skyg.nixos.common.dns.watchdogTimeout` | int | `30` | Watchdog timeout (seconds); auto-reboot if no progress. |
| `skyg.nixos.common.dns.bootCheckRetries` | int | `5` | DNS health check retries during boot. |

## What It Does

1. **Explicitly enables systemd-resolved** (not relying on defaults)
   - `services.resolved.enable = true`
   - Configures stub resolver, DNSSEC tolerance, LLMNR fallback

2. **Hardens journald** to survive corruption
   - `storage = "persistent"` — survive unclean shutdown
   - Automatic vacation/compression
   - Size limits (500M system, 100M runtime)

3. **Adds boot-time DNS verification service** (`dns-boot-check`)
   - Runs after systemd-resolved.service starts
   - Verifies DNS actually responds on 127.0.0.11:53 (5 retries, 1s between)
   - Runs before network-online.target (containers can't start until DNS verified)
   - Fails fast if DNS is dead (watchdog will trigger auto-reboot within 30s)

4. **Enables systemd watchdog** (if DNS or any critical service hangs, reboot)
   - Default: 30-second timeout
   - Automatic recovery much faster than manual intervention (79 min outage → 30s)

5. **Ensures network-online doesn't lie** (waits for actual DNS before claiming ready)

## Usage

**Default behavior** (included in nixos/common, no opt-in needed):
```nix
# In any nixos/common-based config (all hosts):
# DNS is hardened automatically
```

**Customize watchdog timeout** (if 30s is too aggressive/lenient):
```nix
skyg.nixos.common.dns.watchdogTimeout = 60;  # 60 seconds
```

**Disable on specific hosts** (not recommended):
```nix
skyg.nixos.common.dns.enable = false;
```

## Impact

- **Outage prevention:** DNS failures auto-recover within 30s (vs 79-minute manual recovery)
- **Silent failure prevention:** Boot-time check prevents DNS-is-broken scenarios
- **Journald corruption recovery:** Persistent storage + vacuum prevents journal-based startup failures
- **Network reliability:** network-online.target now actually means DNS is ready

## Boot Sequence Impact

**Before this module:**
```
systemd starts → systemd-resolved.service (might fail silently) → 
network-online.target (claims ready, but DNS dead) → 
containers start (DNS queries fail) → 
health checks timeout → outage
```

**After this module:**
```
systemd starts → systemd-resolved.service → 
dns-boot-check service (verify DNS responds) → 
network-online.target (DNS actually ready) → 
containers start (DNS works) → 
health checks pass ✓
```

## Monitoring & Troubleshooting

**Check DNS status at boot:**
```bash
# See if dns-boot-check passed
systemctl status dns-boot-check

# See resolved status
systemctl status systemd-resolved

# Test DNS
dig @127.0.0.11 localhost
nslookup portainer.app.internal
```

**Check journald recovery:**
```bash
# Journald status
journalctl --header
# Should show: Storage: persistent
```

**Check watchdog status:**
```bash
# See if watchdog is active
cat /proc/sys/kernel/watchdog
# Should be non-zero if enabled
```

**If DNS is broken (and watchdog should trigger auto-reboot):**
1. Check `/var/log/journal` for dns-boot-check errors
2. Watchdog should reboot system within 30 seconds
3. If no reboot, manually restart: `systemctl restart systemd-resolved`

## Caveats & Limitations

1. **Watchdog reboot is last resort** — not graceful (use for critical failures only)
2. **DNS verification runs at boot only** — post-boot DNS failures not auto-detected
3. **Lab environment** — DNSSEC set to "allow-downgrade" (not secure); for production, consider "yes"
4. **Stub resolver only** — if full resolver needed, see `services.resolved.extraConfig`

## Related Files

- `modules/nixos/common/containers/container-services/systemd.nix` — containers ordered after dns-boot-check
- `services/resolved.conf(5)` — full resolved configuration options
- `systemd.service(5)` — systemd service unit documentation

## History

- Created after bigbox1 outage (2026-11-16): systemd journal corruption + DNS initialization failure
- Outage duration: 79 minutes
- RCA: unclean shutdown → corrupted journal → dbus load failure → DNS never starts → silent failure

---

**Module:** `modules/nixos/common/dns/`  
**Location:** NixOS flake standard location  
**Scope:** All hosts (default enabled)  
**Maintenance:** Updates to systemd-resolved config may need journal tuning
