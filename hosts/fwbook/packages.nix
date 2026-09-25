{ pkgs, unstablePkgs, ... }:
{
  environment.systemPackages =
    let
      gdk = pkgs.google-cloud-sdk.withExtraComponents (
        with pkgs.google-cloud-sdk.components;
        [
          gke-gcloud-auth-plugin
          kubectl
        ]
      );
    in
    (with pkgs; [
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
      davinci-resolve
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
      devenv
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
      delta
      herdr
      superset-desktop

      skygqts
      hermenix
    ]);
}
