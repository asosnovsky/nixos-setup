{ lib
, stdenvNoCC
, curl
, jq
, cacert
, patchelf
, makeWrapper
, glibc
, libglvnd
, vulkan-loader
, wayland
, xkeyboard_config
}:

# Delta — AI-native code editor from the creators of Zed (delta.dev).
#
# Upstream ships a self-contained tarball (Delta/bin/delta + Delta/lib/*.so).
# There is no stable download URL: the release API returns JSON whose `url`
# field is a short-lived signed R2 link, and the bucket is private. So `src`
# is a fixed-output derivation that resolves the API at build time.
#
# On NixOS we need:
#   1. Interpreter + RPATH fixed (binary expects /lib64/ld-linux-x86-64.so.2).
#      --force-rpath keeps DT_RPATH so the bundled libs' own deps resolve.
#   2. dlopen'd libs (libEGL/libvulkan/libwayland-*) on LD_LIBRARY_PATH.
#   3. XKB_CONFIG_ROOT — the bundled libxkbcommon defaults to /usr/share/X11/xkb.
#
# To bump: set `version`, then run ./update.sh <version>.

let
  pname = "delta-editor";
  version = "0.17.0";

  apiUrl = "https://delta.dev/api/releases/nightly/${version}/asset?asset=delta&os=linux&arch=x86_64";

  src = stdenvNoCC.mkDerivation {
    pname = "${pname}-src";
    inherit version;

    outputHashMode = "flat";
    outputHash = "sha256-+AUZre1HCN2hzmF95jY0Xs0n4Fd/yPnfCTG+QGBt6MU=";

    nativeBuildInputs = [ curl jq cacert ];
    SSL_CERT_FILE = "${cacert}/etc/ssl/certs/ca-bundle.crt";
    CURL_CA_BUNDLE = "${cacert}/etc/ssl/certs/ca-bundle.crt";

    buildCommand = ''
      curl -fsSL '${apiUrl}' | jq -r .url > url
      curl -fsSL "$(cat url)" -o "$out"
    '';
  };
in
stdenvNoCC.mkDerivation {
  inherit pname version src;

  nativeBuildInputs = [ patchelf makeWrapper ];

  # patchelf ships a setup hook that runs `patchelf --shrink-rpath` on every
  # ELF during fixup, which rewrites DT_RPATH as DT_RUNPATH. Disable it so the
  # RPATH we set below survives (RUNPATH is not inherited by the bundled libs).
  dontPatchELF = true;

  unpackPhase = ''
    runHook preUnpack
    tar xzf "$src"
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/delta
    cp -a Delta/. $out/lib/delta/
    chmod -R u+w $out/lib/delta
    rm -f $out/lib/delta/install.sh

    # Fix interpreter + RPATH. --force-rpath keeps DT_RPATH (inherited by the
    # bundled libs) instead of DT_RUNPATH (not inherited).
    patchelf \
      --force-rpath \
      --set-interpreter ${glibc}/lib/ld-linux-x86-64.so.2 \
      --set-rpath '$ORIGIN/../lib:${glibc}/lib' \
      $out/lib/delta/bin/delta

    mkdir -p $out/bin
    makeWrapper $out/lib/delta/bin/delta $out/bin/delta-editor \
      --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [ libglvnd vulkan-loader wayland ]}" \
      --set XKB_CONFIG_ROOT ${xkeyboard_config}/share/X11/xkb

    install -Dm444 $out/lib/delta/share/applications/dev.zed.Delta.desktop \
      $out/share/applications/dev.zed.Delta.desktop
    # Point the launcher at the renamed binary (avoids clashing with the
    # `delta` git diff pager).
    substituteInPlace $out/share/applications/dev.zed.Delta.desktop \
      --replace-fail 'Exec=delta ' 'Exec=delta-editor '
    cp -a $out/lib/delta/share/icons/. $out/share/icons/

    runHook postInstall
  '';

  meta = {
    description = "Delta — AI-native code editor from the creators of Zed";
    homepage = "https://delta.dev";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "delta-editor";
  };
}
