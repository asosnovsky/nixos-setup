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

  # ROCm inputs for the HIP build. hipcc is the raw ROCm compiler, not the
  # nix cc-wrapper, so it needs explicit -I include paths to find the HIP
  # runtime + rocWMMA headers. rocWMMA defines COLI_GPU_HAS_WMMA in
  # backend_gpu_compat.h; without its include dir that macro is undeclared and
  # backend_cuda.cu fails to compile (mirrors the ds4 rocm build inputs).
  rocmInputs = lib.optionals (backend == "rocm") [
    rocmPackages.clr # provides hipcc + HIP runtime
    rocmPackages.rocm-runtime
    rocmPackages.hipblas
    rocmPackages.hipblas-common
    rocmPackages.hipblaslt
    rocmPackages.rocblas
    rocmPackages.rocwmma # gfx1151 backend uses rocWMMA headers
    rocmPackages.hipcub
    rocmPackages.rocprim
    rocmPackages.rocthrust
  ];

  rocmIncludeFlags =
    lib.concatStringsSep " "
      (map (p: "-I${lib.getDev p}/include") rocmInputs);

  hipMakeFlags = lib.optionals (backend == "rocm") [
    "HIP=1"
    "HIP_ARCH=${rocmArch}"
    "ROCM_HOME=${rocmPackages.clr}"
    "HIPCC=${rocmPackages.clr}/bin/hipcc"
  ];

  # HIPCCFLAGS is the Makefile's GPU compile flags (GPUFLAGS). It contains
  # spaces, so it must go through makeFlagsArray (a quoted bash array) rather
  # than makeFlags, which the generic builder word-splits. This reproduces the
  # upstream default flags and appends the rocm include paths.
  hipMakeFlagsArray = lib.optionals (backend == "rocm") [
    "HIPCCFLAGS=-O3 -std=c++17 -x hip --offload-arch=${rocmArch} -Wall -Wextra -fPIE ${rocmIncludeFlags}"
  ];
in
stdenv.mkDerivation {
  pname = "colibri" + lib.optionalString (backend == "rocm") "-rocm";
  version = "1.5.0";

  src = fetchFromGitHub {
    owner = "JustVugg";
    repo = "colibri";
    rev = "8f512fc8c2f48ffa18cd624cd4a5bcaae4a4abfc"; # tag v1.5.0
    hash = "sha256-SW5RDghfITxblAI+nZGVCHULrTQxskzdNHguJkSMfN4=";
  };

  nativeBuildInputs = [ makeWrapper ];
  buildInputs = rocmInputs;

  # python3 is needed by checkPhase: `make test-c` shells out to
  # `python3 tools/run_tests.py`.
  nativeCheckInputs = [ python3 ];

  # Portable AVX2 binary by default; ARCH=native for single-host builds.
  ARCH = if stdenv.hostPlatform.isx86_64 then "x86-64-v3" else "native";

  makeFlags = [ "-C" "c" ] ++ hipMakeFlags;

  # Pass space-containing make variables as a quoted array so they aren't
  # word-split (see hipMakeFlagsArray note above).
  preBuild = lib.optionalString (hipMakeFlagsArray != [ ]) ''
    makeFlagsArray+=(${lib.escapeShellArgs hipMakeFlagsArray})
  '';

  buildFlags = [ "colibri" "olmoe" "deepseek-v4" ];

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
