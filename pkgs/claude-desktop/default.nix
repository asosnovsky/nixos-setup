{ lib
, stdenv
, fetchurl
, dpkg
, autoPatchelfHook
, makeWrapper
, alsa-lib
, at-spi2-atk
, cairo
, cups
, dbus
, expat
, gdk-pixbuf
, glib
, gtk3
, libcap_ng
, libdrm
, libseccomp
, libxkbcommon
, libx11
, libxcomposite
, libxdamage
, libxext
, libxfixes
, libxrandr
, libxcb
, mesa
, nspr
, nss
, pango
, systemd
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "claude-desktop";
  version = "1.22209.0";

  src = fetchurl {
    url = "https://downloads.claude.ai/claude-desktop/apt/stable/pool/main/c/claude-desktop/claude-desktop_${finalAttrs.version}_amd64.deb";
    hash = "sha256:6d18ae792c2bddad01edc97c2c3f4cf489004cefe8fed6760a696ed25c49bf61";
  };

  nativeBuildInputs = [ dpkg autoPatchelfHook makeWrapper ];

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
    libcap_ng
    libdrm
    libseccomp
    libxkbcommon
    libx11
    libxcomposite
    libxdamage
    libxext
    libxfixes
    libxrandr
    libxcb
    mesa
    nspr
    nss
    pango
    systemd
  ];

  unpackPhase = ''
    mkdir -p work
    cd work
    ar x $src
    tar -xf data.tar.xz --no-same-permissions || tar -xf data.tar.xz
    cd ..
    mv work/usr .
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out
    cp -r usr/* $out/

    # Move the original binary and create a wrapper
    mv $out/lib/claude-desktop/claude-desktop $out/lib/claude-desktop/.claude-desktop-wrapped
    makeWrapper $out/lib/claude-desktop/.claude-desktop-wrapped $out/bin/claude-desktop \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [
        mesa
        libxkbcommon
        libx11
        libxcomposite
        libxdamage
        libxext
        libxfixes
        libxrandr
        libxcb
        glib
        nspr
        nss
        cairo
        pango
        gdk-pixbuf
        at-spi2-atk
        dbus
        cups
        systemd
        alsa-lib
      ]}"

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
