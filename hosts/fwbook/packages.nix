{ pkgs, unstablePkgs, nbot, ... }:
let
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
  environment.systemPackages =
    (with pkgs; [
      # Desktop & theme
      glib
      gsettings-desktop-schemas
      gnome-themes-extra
      yaru-theme
      adwaita-icon-theme
      oreo-cursors-plus

      # Screen & images
      grim
      slurp
      wl-clipboard
      wl-screenrec
      gpu-screen-recorder
      gifski
      imagemagick
      zbar
      tesseract

      # Media & creative
      obs-studio
      davinci-resolve-wrapped
      shotcut
      ffmpeg
      krita
      gimp-with-plugins
      simple-scan
      orca-slicer

      # Chat & meetings
      zoom-us
      discord
      betterdiscordctl
      signal-desktop
      telegram-desktop
      unstablePkgs.slack

      # Office
      onlyoffice-desktopeditors
      darling-dmg
      piper-tts

      # Wine
      wineWow64Packages.stable
      winetricks
      wineWow64Packages.waylandFull

      # Cloud, VPN & data
      postgresql
      google-cloud-sdk
      gdk
      awscli
      openfortivpn
      openfortivpn-webview
      openfortivpn-webview-qt
      bitwarden-cli

      # Disks & hardware
      libusb1
      lshw
      parted
      gparted-full
      f3
      rpi-imager
      rpiboot
      libimobiledevice
      ifuse
      idevicerestore

      # Languages & dev tools
      nodejs
      python313
      python314
      uv
      pipx
      cargo
      rustc
      go
      rust-analyzer
      nixd
      kdePackages.qtdeclarative
      just
      unstablePkgs.devcontainer
      unstablePkgs.devenv
      flox_dev
      nix-prefetch
      gh
      bubblewrap
      delta-editor

      # Editors
      unstablePkgs.vscode
      unstablePkgs.zed-editor-fhs
      code-cursor-fhs

      # Agents & LLM tools
      unstablePkgs.claude-code
      unstablePkgs.claude-agent-acp
      unstablePkgs.grok-build
      unstablePkgs.pi-coding-agent
      unstablePkgs.goose-cli
      unstablePkgs.herdr
      unstablePkgs.codex
      unstablePkgs.codex-acp
      nbot.packages.${pkgs.stdenv.hostPlatform.system}.looprail
      hermenix
      unstablePkgs.pi-coding-agent

      # Remote & CLI tools
      unstablePkgs.et
      curl
      jq
      translate-shell
      buzz-desktop
      skygqts
    ]);
}
