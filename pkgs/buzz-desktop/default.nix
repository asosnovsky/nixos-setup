{ lib
, fetchurl
, appimageTools
, runCommand
}:

# Buzz Desktop — self-hostable workspace for humans + AI agents (block/buzz).
#
# Upstream ships a Type-2 AppImage. On NixOS we need:
#   1. FHS libs missing from appimageTools.defaultFhsEnvArgs (elfutils, zstd, …)
#   2. WebKit DMA-BUF disabled — Buzz only auto-enables this when it detects a
#      real AppImage (`APPIMAGE` env). wrapAppImage runs the extracted AppDir.
#   3. Explicit GST_PLUGIN_SYSTEM_PATH_1_0 for WebKit media elements.
#   4. Drop the upstream AppRun hook that hardcodes `GDK_BACKEND=x11` (breaks
#      Wayland clipboard under niri).
#   5. Drop AppImage-bundled OpenSSL 3.0 — AppRun prepends $APPDIR/usr/lib to
#      LD_LIBRARY_PATH, so that old libssl shadows nixpkgs OpenSSL 3.2+ and
#      breaks GStreamer plugins / curl (`OPENSSL_3.2.0' not found`).
#
# To bump: set `version`, then:
#   nix hash file --type sha256 --sri <(curl -fsSL \
#     https://github.com/block/buzz/releases/download/desktop-v${version}/Buzz_${version}_amd64.AppImage)

let
  pname = "buzz-desktop";
  version = "0.5.5";

  src = fetchurl {
    url = "https://github.com/block/buzz/releases/download/desktop-v${version}/Buzz_${version}_amd64.AppImage";
    hash = "sha256-zFHK2mN9YZcSHpXwgyisGcu/7t0+mSIotVLPQ4k+K90=";
  };

  extracted = appimageTools.extractType2 {
    inherit pname version src;
  };

  appdir = runCommand "${pname}-appdir" { } ''
    cp -a ${extracted}/. "$out"
    chmod -R u+w "$out"

    # Prefer Wayland (clipboard) over hard-coded X11 from linuxdeploy.
    hook="$out/apprun-hooks/linuxdeploy-plugin-gtk.sh"
    if [ -f "$hook" ]; then
      sed -i \
        -e 's/^export GDK_BACKEND=x11/# export GDK_BACKEND=x11  # nixos: allow Wayland for clipboard/' \
        "$hook"
    fi

    # AppRun.wrapped forces LD_LIBRARY_PATH=$APPDIR/usr/lib first. The bundled
    # libssl/libcrypto are OpenSSL 3.0.x and lack OPENSSL_3.2.0, which nixpkgs
    # curl / gstreamer plugins need. Remove them so the FHS OpenSSL is used
    # (libssl.so.3 soname is ABI-compatible for this use).
    rm -f \
      "$out/usr/lib"/libssl.so \
      "$out/usr/lib"/libssl.so.* \
      "$out/usr/lib"/libcrypto.so \
      "$out/usr/lib"/libcrypto.so.*
  '';
in
appimageTools.wrapAppImage {
  inherit pname version;
  src = appdir;

  extraPkgs = pkgs: with pkgs; [
    elfutils # libelf.so.1
    zstd # libzstd.so.1
    openssl # replaces removed AppImage OpenSSL
    curl
    webkitgtk_4_1
    libsoup_3
    libayatana-appindicator
    # WebKit media: appsink/appsrc (base), autoaudiosink (good)
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
    gst_all_1.gst-libav
    # Clipboard / desktop integration
    wl-clipboard
    xdg-utils
  ];

  profile = ''
    # WebKit blank-window workaround (Buzz sets this itself only for real AppImages).
    export WEBKIT_DISABLE_DMABUF_RENDERER=1
    export WEBKIT_DISABLE_COMPOSITING_MODE=1

    # Do not force X11 — Wayland clipboard with niri.
    unset GDK_BACKEND
    export GTK_USE_PORTAL=1

    # GStreamer plugins from the FHS root (after AppDir OpenSSL removal they
    # can load nixpkgs plugins that need OpenSSL 3.2+).
    export GST_PLUGIN_SYSTEM_PATH_1_0="/usr/lib/gstreamer-1.0''${GST_PLUGIN_SYSTEM_PATH_1_0:+:$GST_PLUGIN_SYSTEM_PATH_1_0}"
    export GST_PLUGIN_PATH="/usr/lib/gstreamer-1.0''${GST_PLUGIN_PATH:+:$GST_PLUGIN_PATH}"
  '';

  extraInstallCommands = ''
    install -Dm444 ${appdir}/usr/share/applications/Buzz.desktop \
      $out/share/applications/buzz-desktop.desktop
    substituteInPlace $out/share/applications/buzz-desktop.desktop \
      --replace-fail 'Exec=buzz-desktop' 'Exec=${pname}' \
      --replace-fail 'Icon=buzz-desktop' 'Icon=${pname}'

    for size in 32x32 128x128 '256x256@2'; do
      if [ -f ${appdir}/usr/share/icons/hicolor/$size/apps/buzz-desktop.png ]; then
        install -Dm644 ${appdir}/usr/share/icons/hicolor/$size/apps/buzz-desktop.png \
          $out/share/icons/hicolor/$size/apps/${pname}.png
      fi
    done
    if [ ! -e $out/share/icons/hicolor/128x128/apps/${pname}.png ] \
       && [ -f ${appdir}/buzz-desktop.png ]; then
      install -Dm644 ${appdir}/buzz-desktop.png \
        $out/share/icons/hicolor/128x128/apps/${pname}.png
    fi
  '';

  meta = {
    description = "Buzz desktop — self-hostable workspace for humans and AI agents";
    homepage = "https://github.com/block/buzz";
    changelog = "https://github.com/block/buzz/releases/tag/desktop-v${version}";
    license = lib.licenses.asl20;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "buzz-desktop";
  };
}
