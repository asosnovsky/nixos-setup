# configs/hl-fws1/hypr/dms/

Placeholder for DMS-generated Hyprland overrides (colors / layout / window
rules), mirroring `configs/fwbook/hypr/dms/`.

Nothing is mounted here yet, so nothing is required from `hyprland.lua`. When
DMS config is wired into this host, the generated `dms/*.lua` files will live
here and can be pulled in with `require("dms.layout")`, etc.