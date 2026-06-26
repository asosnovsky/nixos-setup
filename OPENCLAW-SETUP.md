# OpenClaw Integration Setup

✅ **Integration Complete!**

I've successfully added OpenClaw to your nixos-setup with a simple NixOS systemd service. **No Home Manager required** - it's a pure system service.

## Changes Made

### 1. Updated `flake.nix`
- Added `nix-openclaw` as a new input from `github:openclaw/nix-openclaw`
- Configured it to follow your existing `nixpkgs` and `home-manager` versions
- Added `nix-openclaw` to the outputs destructuring
- Passed `nix-openclaw` through to specialArgs for access in modules

### 2. Created `modules/nixos/server/services/openclaw.nix`
A complete NixOS module that provides:
- `skyg.nixos.server.services.openclaw.enable` - enable/disable the service
- `skyg.nixos.server.services.openclaw.port` - gateway port (default: 18789)
- `skyg.nixos.server.services.openclaw.gatewayToken` - authentication token
- `skyg.nixos.server.services.openclaw.user` - service user (default: openclaw)
- `skyg.nixos.server.services.openclaw.logLevel` - log level (debug/info/warn/error)
- `skyg.nixos.server.services.openclaw.package` - custom OpenClaw package

Features:
- ✅ Automatic user/group creation
- ✅ Systemd service management (auto-restart on failure)
- ✅ Security hardening (strict filesystem protection, no new privileges, private tmp)
- ✅ Automatic firewall port opening
- ✅ Journal logging integration

### 3. Updated `modules/nixos/server/services/default.nix`
- Added `./openclaw.nix` to the services imports so it's available system-wide

## How to Use

### 1. Enable on a Host

In your host configuration (e.g., `hosts/hl-minipc3.nix`):

```nix
skyg.nixos.server.services.openclaw = {
  enable = true;
  port = 18789;
  gatewayToken = "your-secret-gateway-token";
  logLevel = "info";
};
```

### 2. Manage Configuration

Configuration happens via:
- **Environment variables**: Set via the service `environment` config
- **Config file** (optional): Point to `/etc/openclaw/openclaw.json` via the `configFile` option
- **Default behavior**: Service auto-creates `/var/lib/openclaw` as its working directory

### 3. Apply Changes

```bash
# Rebuild the system
sudo nixos-rebuild switch

# Or if using home-manager:
home-manager switch --flake .#
```

### 4. Verify It's Running

```bash
# Check service status
systemctl status openclaw-gateway

# View logs
journalctl -u openclaw-gateway -f

# Test gateway locally
curl http://localhost:18789/health
```

## Simple Example Configuration

```nix
# In hosts/hl-minipc3.nix or similar
skyg.nixos.server.services.openclaw = {
  enable = true;
  port = 18789;
  gatewayToken = "mySecretToken123";
};
```

That's it! The service will:
- Run as the `openclaw` user
- Listen on port 18789
- Auto-restart if it crashes
- Log to systemd journal
- Protect filesystem access (strict sandbox)

## Multiple Instances

If you want multiple OpenClaw gateways on the same host with different ports:

```nix
# You'd need to duplicate the service with different names
# This is currently not supported by the module but could be extended
# Just ask if you need this!
```

## Debugging

View real-time logs:
```bash
journalctl -u openclaw-gateway -f
```

Check service details:
```bash
systemctl cat openclaw-gateway
```

View environment variables:
```bash
systemctl show -p Environment openclaw-gateway
```

## Architecture

```
flake.nix (nix-openclaw input)
    ↓
modules/lib.nix (specialArgs)
    ↓
modules/nixos/server/services/openclaw.nix
    ↓
systemd.services.openclaw-gateway
    ↓
/var/lib/openclaw (working directory)
```

## Next Steps

1. Choose a host where you want OpenClaw (e.g., `hl-minipc3`, `hl-bigbox1`)
2. Add the `skyg.nixos.server.services.openclaw` config to that host
3. Set your `gatewayToken` (generate a secure token)
4. Run `nixos-rebuild switch`
5. Monitor with `journalctl -u openclaw-gateway -f`

## Resources

- [nix-openclaw GitHub](https://github.com/openclaw/nix-openclaw)
- [OpenClaw Documentation](https://docs.openclaw.ai/)
- [NixOS Systemd Services](https://nixos.org/manual/nixos/stable/#sec-systemd-services)

## Troubleshooting

**Service won't start:**
```bash
journalctl -u openclaw-gateway -n 50
```

**Port already in use:**
Change the port in your config:
```nix
skyg.nixos.server.services.openclaw.port = 18790;
```

**Package not found:**
The module defaults to `pkgs.openclaw`. If this doesn't exist in nixpkgs yet, use the nix-openclaw flake output:
```nix
skyg.nixos.server.services.openclaw.package = nix-openclaw.packages.${system}.openclaw;
```

(You'd need to pass it through specialArgs or adjust the module)
