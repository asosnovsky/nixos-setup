{ lib, stdenvNoCC, fetchurl }:

# Grok CLI — xAI's command-line coding agent.
#
# Upstream ships prebuilt, self-contained binaries (static-pie ELF on Linux,
# Mach-O on macOS) via the installer at https://x.ai/cli/install.sh. There is no
# public source build, so we just fetch the right artifact per platform and drop
# it in $out/bin. No patchelf/autoPatchelfHook is needed — the Linux binary is
# statically linked.
#
# To bump: set `version` and refresh the hashes. The latest stable version is at
#   https://storage.googleapis.com/grok-build-public-artifacts/cli/stable
# and the per-platform hash is:
#   nix hash file --type sha256 --sri \
#     <(curl -fsSL https://storage.googleapis.com/grok-build-public-artifacts/cli/grok-<version>-<platform>)

let
  version = "0.2.33";

  baseUrl = "https://storage.googleapis.com/grok-build-public-artifacts/cli";

  # nix system → { upstream platform slug, artifact hash }
  sources = {
    "x86_64-linux" = {
      platform = "linux-x86_64";
      hash = "sha256-DAd7As5qRqZkm8G7eSva05acwbL6ZzCmTPm67opkKEM=";
    };
    "aarch64-linux" = {
      platform = "linux-aarch64";
      hash = "sha256-Csl/20RdR5/skH2Zdv0FeuBwU7wHdXSRZ1iCp0lB88A=";
    };
    "x86_64-darwin" = {
      platform = "macos-x86_64";
      hash = "sha256-UzLQHZ2UXljG2rfmGxXPA0jLkHoung/UnVBtlvV3Uxg=";
    };
    "aarch64-darwin" = {
      platform = "macos-aarch64";
      hash = "sha256-ifFeGIepNtlhYCJj4kmZuQD/mjZGjizzKSQSjOS1LoA=";
    };
  };

  system = stdenvNoCC.hostPlatform.system;
  source = sources.${system} or (throw "grok-cli: unsupported system '${system}'");
in
stdenvNoCC.mkDerivation {
  pname = "grok-cli";
  inherit version;

  src = fetchurl {
    url = "${baseUrl}/grok-${version}-${source.platform}";
    inherit (source) hash;
  };

  dontUnpack = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 "$src" "$out/bin/grok"
    # Upstream installs an `agent` alias alongside `grok` (the binary dispatches
    # on argv[0]); preserve it.
    ln -s grok "$out/bin/agent"
    runHook postInstall
  '';

  # The Linux artifact is static-pie linked, so the only check we can run is the
  # one the upstream installer does: confirm it executes.
  doInstallCheck = stdenvNoCC.hostPlatform.isLinux;
  installCheckPhase = ''
    "$out/bin/grok" --version </dev/null >/dev/null
  '';

  meta = {
    description = "xAI's Grok command-line coding agent";
    homepage = "https://x.ai/cli";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = builtins.attrNames sources;
    mainProgram = "grok";
  };
}
