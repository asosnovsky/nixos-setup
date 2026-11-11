{ pkgs, nixarchy, skygUtils, config, ... }:
let
  # Omarchy shell build
  dedent = "${pkgs.gawk}/bin/awk 'BEGIN{m=9999} {l[NR]=$0; match($0,/^ */); if ($0 ~ /[^ ]/ && RLENGTH<m) m=RLENGTH} END{for(i=1;i<=NR;i++) print substr(l[i],m+1)}'";
  omarchy = ((pkgs.extend nixarchy.overlays.default).omarchy).overrideAttrs (old: {
    installPhase = builtins.replaceStrings
      [ "python3 -c '" "' $menu\n" ]
      [ "python3 -c \"$(printf '%s' '" "' | ${dedent})\" $menu\n" ]
      old.installPhase;
  });
  # The shell's runtime deps, minus hyprland (we keep the flake's Hyprland).
  # Omarchy runtime deps
  omarchyRuntime = builtins.filter
    (d: !(pkgs.lib.hasPrefix "hyprland-" (d.name or "")))
    omarchy.passthru.runtimeDeps;
in
{
  # Omarchy env vars (shell resolves paths via OMARCHY_PATH)
  environment.sessionVariables.OMARCHY_PATH = "${omarchy}/share/omarchy";
  environment.sessionVariables.OMARCHY_SCREENSHOT_EDITOR = "satty-edit";

  # Omarchy config link: ~/.config/omarchy -> configs/fwbook/omarchy
  system.userActivationScripts.omarchyConfig.text =
    skygUtils.makeHyperlinkScriptToConfigs {
      filePath = "fwbook/omarchy";
      targetPath = "omarchy";
      configSource = "/home/${config.skyg.user.name}/nixos-setup/configs";
    };

  # Packages
  environment.systemPackages =
    [ omarchy ]
    ++ omarchyRuntime;
}
