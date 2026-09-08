import Quickshell

// Standalone clock shell for hl-pi1: a single full-screen overlay window
// showing a big digital clock (left) and a simple calendar (right) on a black
// background. Run with `qs -c clock`; autostarted from Hyprland and autologin
// into Hyprland means it's the entire desktop.
ShellRoot {
    ClockPanel {}
}