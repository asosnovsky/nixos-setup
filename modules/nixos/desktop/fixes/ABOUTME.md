# modules/nixos/desktop/fixes/

Various workarounds and fixes for desktop/workstation issues.

## Files

```
fixes/
├── default.nix    # skyg.nixos.desktop.fixes.airpod-bluetooth.enabled — AirPods HFP mic
└── fingerprint-autosuspend.nix
                   # skyg.nixos.desktop.fixes.fingerprint-autosuspend.enabled — keep fingerprint reader awake
```

## Behaviour

### AirPods Bluetooth Audio Fix

When `skyg.nixos.desktop.fixes.airpod-bluetooth.enabled` is set to `true`:

- WirePlumber auto-switches AirPods from A2DP to HFP when an app opens a mic.
- Enables native HFP plus mSBC so the AirPods mic shows as an input.
- Call audio is headset quality (mSBC if the buds support it), not A2DP.

### Fingerprint Reader Autosuspend Fix

When `skyg.nixos.desktop.fixes.fingerprint-autosuspend.enabled` is set to `true`:

- Adds a udev rule keeping the Goodix MOC fingerprint reader (`27c6:609c`)
  out of USB autosuspend (`power/control=on`, `autosuspend_delay_ms=-1`).
- Prevents the recurring `usb 1-4: reset full-speed USB device` resets and the
  intermittent fprintd failure `Device reported an error during identify:
  Cannot run while suspended` caused by probing the reader while it is asleep.
