{ lib
, stdenv
, fetchurl
, dpkg
, autoPatchelfHook
, makeWrapper
, wrapGAppsHook3
, alsa-lib
, at-spi2-atk
, cairo
, cups
, dbus
, expat
, gdk-pixbuf
, glib
, gtk3
, libdrm
, libxkbcommon
, mesa
, nspr
, nss
, pango
, systemd
, xorg
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "claude-desktop";
  version = "1.22209.0";

  src = fetchurl {
    url = "https://downloads.claude.ai/claude-desktop/apt/stable/pool/main/c/claude-desktop/claude-desktop_${finalAttrs.version}_amd64.deb";
    hash = "6d18ae792c2bddad01edc97c2c3f4cf489004cefe8fed6760a696ed25c49bf61";
  };

  nativeBuildInputs = [ dpkg autoPatchelfHook makeWrapper wrapGAppsHook3 ];

  buildInputs = [
    alsa-lib
    at-spi2-atk
    cairo
    cups
    dbus
    expat
    gdk-pixbuf
    glib
    gtk3
    libdrm
    libxkbcommon
    mesa
    nspr
    nss
    pango
    systemd
    xorg.libX11
    xorg.libXcomposite
    xorg.libXdamage
    xorg.libXext
    xorg.libXfixes
    xorg.libXrandr
    xorg.libxcb
  ];

  unpackPhase = "dpkg-deb -x $src .";

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r usr/* $out/

    # Adjust to the real executable path revealed by: dpkg-deb -c the.deb
    makeWrapper $out/lib/claude-desktop/claude-desktop $out/bin/claude-desktop \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ mesa ]}"

    # Fix desktop-file Exec/Icon paths if present
    if [ -d usr/share/applications ]; then
      substituteInPlace $out/share/applications/*.desktop \
        --replace-quiet "/usr/bin/claude-desktop" "$out/bin/claude-desktop" || true
    fi
    runHook postInstall
  '';

  meta = {
    description = "Claude Desktop for Linux";
    homepage = "https://claude.ai/download";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" "aarch64-linux" ];
    mainProgram = "claude-desktop";
  };
})
