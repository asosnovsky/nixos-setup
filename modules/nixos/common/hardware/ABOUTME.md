# modules/nixos/common/hardware/

Per-device hardware modules. `default.nix` imports them all and turns on a couple of
always-safe defaults (`services.fwupd`, `hardware.enableAllFirmware`); each specific module
is gated by its own `skyg.nixos.common.hardware.*` enable flag so a host only pulls in what
its physical hardware needs.

## Files

```
hardware/
├── default.nix         # imports + fwupd + enableAllFirmware
├── amdgpu.nix          # skyg.nixos.common.hardware.amdgpu — amdgpu driver + ROCm ICD
├── nvidia.nix          # skyg.nixos.common.hardware.nvidia — driver + container toolkit
├── sound.nix           # skyg.nixos.common.hardware.sound — PipeWire ALSA/JACK + rtkit
├── pipewire.nix        # skyg.nixos.common.hardware.pipewire — full PipeWire stack
├── fan2go.nix          # skyg.nixos.common.hardware.fan2go — fan2go curve-based fan control
├── fancontrol.nix      # skyg.nixos.common.hardware.fancontrol — lm_sensors fancontrol
├── laptop-power.nix    # skyg.nixos.common.hardware.laptop-power-mgr — lid events + power mgmt
└── coral-tpu-udev.nix  # skyg.nixos.common.hardware.udevrules.coraltpu — Coral TPU udev rules
```

## Option Namespace

```
skyg.nixos.common.hardware.amdgpu.enable
skyg.nixos.common.hardware.nvidia.enable
skyg.nixos.common.hardware.sound.enable
skyg.nixos.common.hardware.pipewire.enable
skyg.nixos.common.hardware.fan2go.{enable,dbPath}
skyg.nixos.common.hardware.fancontrol.{enable,configName}
skyg.nixos.common.hardware.laptop-power-mgr.enable
skyg.nixos.common.hardware.udevrules.coraltpu.{enable,symlinkName}
```

## Conventions

- One module per hardware concern; each defaults to `false` and is enabled per-host based on
  the machine's actual hardware.
- `fan2go` and `fancontrol` are alternatives — pick one per host depending on the board.
- Keep these orthogonal to `*.hardware-configuration.nix` (that file is generated and must
  never be hand-edited).
