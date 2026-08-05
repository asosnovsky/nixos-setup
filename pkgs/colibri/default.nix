{ lib
, stdenv
, fetchFromGitHub
, makeWrapper
, python3
, rocmPackages
, backend ? "cpu" # one of "cpu" | "rocm"
, rocmArch ? "gfx1151" # AMD Strix Halo (Framework Desktop iGPU)
}:

# colibrì (JustVugg/colibri) — run GLM-5.2 (744B MoE) and other frontier MoE
# models locally from a pure-C engine with experts streamed from disk.
# Upstream ships its own `make install` target (installs `coli` to bin/ and
# the engine binaries + support .py modules to libexec/colibri/), and `coli`
# already knows how to find libexec/colibri/ relative to its own install
# path — so we lean on that instead of re-deriving the file layout by hand.
#
# This derivation is backend-parameterized like pkgs/ds4: pick the GPU
# backend with `backend` ("cpu" | "rocm"). The overlay in
# modules/core/default.nix wires up `colibri` (cpu) and `colibri-rocm`.
#
# To bump: set `rev` to the new tag's commit and refresh `hash` (start from
# lib.fakeHash and copy the SRI hash from the build error).

assert lib.elem backend [ "cpu" "rocm" ];

let
  # Only `coli convert` / `coli bench` need these; chat/serve just exec the
  # compiled engine binary.
  pythonEnv = python3.withPackages (
    ps: with ps; [
      torch
      safetensors
      huggingface-hub
      numpy
      tokenizers
      datasets
    ]
  );

  hipMakeFlags = lib.optionals (backend == "rocm") [
    "HIP=1"
    "HIP_ARCH=${rocmArch}"
    "ROCM_HOME=${rocmPackages.clr}"
    "HIPCC=${rocmPackages.clr}/bin/hipcc"
  ];
in
stdenv.mkDerivation {
  pname = "colibri" + lib.optionalString (backend == "rocm") "-rocm";
  version = "1.5.0";

  src = fetchFromGitHub {
    owner = "JustVugg";
    repo = "colibri";
    rev = "8f512fc8c2f48ffa18cd624cd4a5bcaae4a4abfc"; # tag v1.5.0
    hash = lib.fakeHash; # replace with the real hash on first build attempt
  };

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = lib.optionals (backend == "rocm") [
    rocmPackages.clr
    rocmPackages.rocm-runtime
    rocmPackages.hipblas
  ];

  # python3 is needed by checkPhase: `make test-c` shells out to
  # `python3 tools/run_tests.py`.
  nativeCheckInputs = [ python3 ];

  # Portable AVX2 binary by default; ARCH=native for single-host builds.
  ARCH = if stdenv.hostPlatform.isx86_64 then "x86-64-v3" else "native";

  makeFlags = [ "-C" "c" ] ++ hipMakeFlags;
  buildFlags = [ "colibri" "olmoe" ];

  # Use upstream's own install target instead of hand-copying files — it
  # installs `coli` to bin/ and the engine + support modules to
  # libexec/colibri/, which `coli` already knows how to find on its own.
  installPhase = ''
    runHook preInstall
    make -C c install PREFIX=$out ARCH="$ARCH" ${lib.escapeShellArgs hipMakeFlags}
    runHook postInstall
  '';

  # coli ships `#!/usr/bin/env python3`; point env at pythonEnv so the
  # converter/bench subcommands resolve torch etc. No COLI_ENGINE/PYTHONPATH
  # override needed — coli auto-detects bin/ + libexec/colibri/ relative to
  # its own installed path.
  postFixup = ''
    wrapProgram $out/bin/coli --prefix PATH : ${lib.makeBinPath [ pythonEnv ]}
  '';

  # rocm skips: test-c would relink the engine without HIP=1, clobbering the
  # GPU build, and needs real hardware anyway.
  doCheck = backend == "cpu";
  checkPhase = ''
    runHook preCheck
    cd c
    make test-c
    cd ..
    runHook postCheck
  '';

  meta = {
    description = "Run GLM-5.2 (744B MoE) and other frontier MoE models on hardware you already own";
    homepage = "https://github.com/JustVugg/colibri";
    license = lib.licenses.asl20;
    sourceProvenance = [ lib.sourceTypes.fromSource ];
    platforms =
      if backend == "rocm"
      then lib.platforms.linux
      else lib.platforms.linux ++ lib.platforms.darwin;
    mainProgram = "coli";
  };
}
