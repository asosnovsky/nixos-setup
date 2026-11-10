{ pkgs, unstablePkgs, nixarchy, skygUtils, config, nbot, ... }:
let
  dedent = "${pkgs.gawk}/bin/awk 'BEGIN{m=9999} {l[NR]=$0; match($0,/^ */); if ($0 ~ /[^ ]/ && RLENGTH<m) m=RLENGTH} END{for(i=1;i<=NR;i++) print substr(l[i],m+1)}'";
  omarchy = ((pkgs.extend nixarchy.overlays.default).omarchy).overrideAttrs (old: {
    installPhase = builtins.replaceStrings
      [ "python3 -c '" "' $menu\n" ]
      [ "python3 -c \"$(printf '%s' '" "' | ${dedent})\" $menu\n" ]
      old.installPhase;
  });
  # The shell's runtime deps, minus hyprland (we keep the flake's Hyprland).
  omarchyRuntime = builtins.filter
    (d: !(pkgs.lib.hasPrefix "hyprland-" (d.name or "")))
    omarchy.passthru.runtimeDeps;
  gdk = pkgs.google-cloud-sdk.withExtraComponents (
    with pkgs.google-cloud-sdk.components;
    [
      gke-gcloud-auth-plugin
      kubectl
    ]
  );
  davinci-resolve-wrapped = pkgs.symlinkJoin {
    name = "davinci-resolve";
    paths = [ pkgs.davinci-resolve ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/davinci-resolve --set QT_QPA_PLATFORM xcb
    '';
  };
in
{
  # The shell resolves everything through OMARCHY_PATH.
  environment.sessionVariables.OMARCHY_PATH = "${omarchy}/share/omarchy";
  environment.sessionVariables.OMARCHY_SCREENSHOT_EDITOR = "satty-edit";

  # ~/.config/omarchy -> configs/fwbook/omarchy (same pattern as hypr/noctalia).
  system.userActivationScripts.omarchyConfig.text =
    skygUtils.makeHyperlinkScriptToConfigs {
      filePath = "fwbook/omarchy";
      targetPath = "omarchy";
      configSource = "/home/${config.skyg.user.name}/nixos-setup/configs";
    };

  environment.systemPackages =
    [ omarchy ]
    ++ omarchyRuntime
    ++ (with pkgs; [
      glib
      gsettings-desktop-schemas
      gnome-themes-extra
      yaru-theme
      adwaita-icon-theme
    ])
    ++ (with pkgs; [
      grim
      slurp
      wl-clipboard
      tesseract
      imagemagick
      zbar
      curl
      translate-shell
      wl-screenrec
      ffmpeg
      gifski
      libusb1
      lshw
      jq
      parted
      gparted-full
      f3
      nixd
      kdePackages.qtdeclarative
      piper-tts
      ffmpeg
      oreo-cursors-plus

      postgresql
      google-cloud-sdk
      awscli
      openfortivpn
      openfortivpn-webview
      openfortivpn-webview-qt
      nodejs

      wineWow64Packages.stable
      winetricks
      wineWow64Packages.waylandFull

      obs-studio
      davinci-resolve-wrapped
      grim
      slurp
      wl-clipboard
      tesseract
      imagemagick
      zbar
      curl
      translate-shell
      wl-screenrec
      ffmpeg
      gifski
      jq

      krita
      gimp-with-plugins
      shotcut
      simple-scan

      zoom-us
      betterdiscordctl
      discord
      signal-desktop
      telegram-desktop

      python313
      python314
      uv
      cargo
      rustc
      go
      pipx
      rust-analyzer

      vscode
      unstablePkgs.zed-editor-fhs
      unstablePkgs.et
      unstablePkgs.devenv
      just
      rpi-imager
      rpiboot
      code-cursor-fhs
      nix-prefetch
      orca-slicer
      devcontainer
      gpu-screen-recorder
      flox_dev

      darling-dmg

      bitwarden-cli

      onlyoffice-desktopeditors

      gh
      gdk
      unstablePkgs.slack

      libimobiledevice
      ifuse

      idevicerestore

      unstablePkgs.grok-build
      unstablePkgs.pi-coding-agent
      unstablePkgs.goose-cli
      unstablePkgs.claude-agent-acp
      unstablePkgs.claude-code
      buzz-desktop
      bubblewrap
      delta-editor
      herdr
      nbot.packages.${pkgs.stdenv.hostPlatform.system}.nbot-wf

      skygqts
      hermenix
    ]);
}
