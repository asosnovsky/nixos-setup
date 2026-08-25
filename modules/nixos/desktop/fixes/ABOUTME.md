# modules/nixos/desktop/fixes/

Various workarounds and fixes for desktop/workstation issues.

## Files

```
fixes/
└── default.nix    # skyg.nixos.desktop.fixes.airpod-bluetooth.enabled — AirPods distorted/robotic audio fix
```

## Behaviour

### AirPods Bluetooth Audio Fix
When `skyg.nixos.desktop.fixes.airpod-bluetooth.enabled` is set to `true`:
- WirePlumber's auto-switching behavior is disabled for the AirPods.
- Prevents switching from high-quality A2DP profile to low-quality HFP/HSP mono profile when a mic stream opens.
- Dictates that AirPods stay in A2DP permanently, while meeting/chat apps fall back to the laptop's built-in mic for input.
