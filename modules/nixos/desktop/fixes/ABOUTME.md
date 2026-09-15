# modules/nixos/desktop/fixes/

Various workarounds and fixes for desktop/workstation issues.

## Files

```
fixes/
└── default.nix    # skyg.nixos.desktop.fixes.airpod-bluetooth.enabled — AirPods HFP mic
```

## Behaviour

### AirPods Bluetooth Audio Fix

When `skyg.nixos.desktop.fixes.airpod-bluetooth.enabled` is set to `true`:

- WirePlumber auto-switches AirPods from A2DP to HFP when an app opens a mic.
- Enables native HFP plus mSBC so the AirPods mic shows as an input.
- Call audio is headset quality (mSBC if the buds support it), not A2DP.
