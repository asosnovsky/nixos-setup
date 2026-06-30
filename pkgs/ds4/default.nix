{ lib
, stdenv
, fetchFromGitHub
, makeWrapper
, curl
, cacert
, rocmPackages
, cudaPackages
  # backend selects the build target / toolchain.
, backend ? "cpu" # one of "cpu" | "rocm" | "cuda"
  # CUDA: null => `cuda-generic` (CUDA_ARCH=native, build host == GPU host);
  # set e.g. "sm_89" to pin an arch via `make cuda CUDA_ARCH=sm_89`.
, cudaArch ? null
  # ROCm: GPU target. gfx1151 == AMD Strix Halo (the upstream default).
, rocmArch ? "gfx1151"
}:

# DwarfStar (antirez/ds4) — a from-source DeepSeek V4 Flash/PRO local inference
# engine. Upstream is a hand-written Makefile with no `install` target and no
# tagged releases, so we pin a `main` commit and write our own installPhase.
#
# This derivation is *backend-parameterized*: pick the GPU backend with the
# `backend` argument ("cpu" | "rocm" | "cuda"). The overlay in
# modules/core/default.nix wires up `ds4` (cpu), `ds4-rocm`, and `ds4-cuda`.
#
# Build-per-host: we keep upstream's `-march=native` default (NATIVE_CPU_FLAG),
# so the resulting store paths are CPU-specific and are NOT safe to share across
# heterogeneous machines. Build each variant on (or for) its target host. The
# GPU variants must be built on a machine carrying the matching toolchain.
#
# To bump: set `rev` to the new `main` HEAD and refresh `hash` (start from
# lib.fakeHash and copy the SRI hash from the build error, or use
# `nix-prefetch-url --unpack https://github.com/antirez/ds4/archive/<rev>.tar.gz`
# then `nix hash to-sri --type sha256 <hash>`).

assert lib.elem backend [ "cpu" "rocm" "cuda" ];

let
  # ROCm libraries the gfx kernels and link flags (-lhipblas -lhipblaslt) need.
  rocmInputs = [
    rocmPackages.clr # provides hipcc + HIP runtime
    rocmPackages.hipblas
    rocmPackages.hipblas-common # hipblas.h includes hipblas-common/hipblas-common.h
    rocmPackages.hipblaslt
    rocmPackages.rocblas
    rocmPackages.rocwmma # gfx1151 backend uses rocWMMA headers
    rocmPackages.hipcub
    rocmPackages.rocprim
    rocmPackages.rocthrust
    rocmPackages.rocm-runtime
  ];

  # -L<dir> and matching rpath so the linked binaries resolve the ROCm .so's
  # from the store at runtime (upstream assumes /opt/rocm on PATH).
  rocmLibDirs = map (p: "${lib.getLib p}/lib") rocmInputs;
  rocmLinkFlags =
    lib.concatStringsSep " "
      (map (d: "-L${d} -Wl,-rpath,${d}") rocmLibDirs);
  rocmIncludeFlags =
    lib.concatStringsSep " "
      (map (p: "-I${lib.getDev p}/include") rocmInputs);

  # CUDA libs we link against; nvcc is the linker for the cuda build.
  cudaLibDirs = [
    "${lib.getLib cudaPackages.cuda_cudart}/lib"
    "${lib.getLib cudaPackages.libcublas}/lib"
  ];
  cudaLinkFlags =
    lib.concatStringsSep " "
      (map (d: "-L${d} -Xlinker -rpath -Xlinker ${d}") cudaLibDirs);

  # phony Makefile target per backend.
  buildTarget = {
    cpu = "cpu";
    rocm = "strix-halo";
    cuda = if cudaArch == null then "cuda-generic" else "cuda";
  }.${backend};

  # Per-backend command-line variable overrides (forwarded to the recursive
  # sub-make as MAKEOVERRIDES, beating the Makefile's `?=` defaults).
  #
  # `makeFlags` entries are expanded UNQUOTED by the generic builder, so any
  # value containing spaces (CFLAGS/LDLIBS) would be word-split and make would
  # treat the extra words as bogus options. Those go through `makeFlagsArray`
  # (a quoted bash array, set in preBuild) instead; only space-free assignments
  # may live in `makeFlags`.
  backendMakeFlags = {
    cpu = [ ];
    rocm = [ "ROCM_ARCH=${rocmArch}" ];
    cuda = [
      "NVCC=${lib.getExe' cudaPackages.cuda_nvcc "nvcc"}"
      "CUDA_HOME=${cudaPackages.cuda_nvcc}"
    ] ++ lib.optional (cudaArch != null) "CUDA_ARCH=${cudaArch}";
  }.${backend};

  # Space-containing variable assignments (must survive word splitting).
  backendMakeFlagsArray = {
    cpu = [ ];
    rocm = [
      # Append store include/lib paths to the upstream ROCm flags (hipcc is the
      # raw ROCm compiler, not the nix cc-wrapper, so it needs explicit -I/-L).
      "ROCM_CFLAGS=-O3 -ffast-math -g -fno-finite-math-only -pthread -D__HIP_PLATFORM_AMD__ -Wno-unused-command-line-argument --offload-arch=${rocmArch} ${rocmIncludeFlags}"
      "ROCM_LDLIBS=-lm -pthread ${rocmLinkFlags} -lhipblas -lhipblaslt"
    ];
    cuda = [
      # Replace upstream's hardcoded /usr/local/cuda + sbsa-linux (aarch64)
      # paths with the nixpkgs cudart/cublas store paths.
      "CUDA_LDLIBS=-lm -Xcompiler -pthread ${cudaLinkFlags} -lcudart -lcublas"
    ];
  }.${backend};
in
stdenv.mkDerivation (finalAttrs: {
  pname = "ds4" + lib.optionalString (backend != "cpu") "-${backend}";
  version = "0-unstable-2026-06-17";

  src = fetchFromGitHub {
    owner = "antirez";
    repo = "ds4";
    rev = "80ebbc396aee40eedc1d829222f3362d10fa4c6c";
    hash = "sha256-Ieuc72GHZs20ModQfnvI5Me31n4Pj+WFYtsuqaKJceo=";
  };

  enableParallelBuilding = true;

  nativeBuildInputs =
    [ makeWrapper ]
    ++ lib.optionals (backend == "rocm") [ rocmPackages.clr ]
    ++ lib.optionals (backend == "cuda") [ cudaPackages.cuda_nvcc ];

  buildInputs =
    lib.optionals (backend == "rocm") rocmInputs
    ++ lib.optionals (backend == "cuda") [
      cudaPackages.cuda_cudart
      cudaPackages.libcublas
    ];

  makeFlags = backendMakeFlags;
  buildFlags = [ buildTarget ];

  # Pass space-containing make variables as a quoted array so they aren't
  # word-split (see backendMakeFlagsArray note above).
  preBuild = lib.optionalString (backendMakeFlagsArray != [ ]) ''
    makeFlagsArray+=(${lib.escapeShellArgs backendMakeFlagsArray})
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 -t "$out/bin" ds4 ds4-server ds4-bench ds4-eval ds4-agent

    # Wire upstream's GGUF downloader in as `ds4-download-model`. Patch its
    # project-root detection so the gguf dir and the `ds4flash.gguf` symlink
    # land in a writable location ($DS4_HOME, default: cwd) instead of the
    # read-only store dir that `dirname $0` would resolve to here.
    install -Dm755 download_model.sh "$out/bin/ds4-download-model"
    substituteInPlace "$out/bin/ds4-download-model" \
      --replace-fail 'ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)' 'ROOT=''${DS4_HOME:-$PWD}' \
      --replace-warn './download_model.sh' 'ds4-download-model'
    runHook postInstall
  '';

  # `ds4-download-model` shells out to curl (and optionally the `hf` CLI for the
  # huge PRO files); make curl available and point it at a CA bundle if the
  # environment doesn't already set one.
  postFixup = ''
    wrapProgram "$out/bin/ds4-download-model" \
      --prefix PATH : ${lib.makeBinPath [ curl ]} \
      --set-default SSL_CERT_FILE ${cacert}/etc/ssl/certs/ca-bundle.crt
  '';

  # Only the CPU variant is guaranteed to run without a GPU/device present, so
  # restrict the smoke check to it. GPU variants are validated on real hardware.
  doInstallCheck = backend == "cpu";
  installCheckPhase = ''
    runHook preInstallCheck
    "$out/bin/ds4" --help >/dev/null
    runHook postInstallCheck
  '';

  meta = {
    description = "DeepSeek V4 Flash/PRO local inference engine (DwarfStar)";
    homepage = "https://github.com/antirez/ds4";
    license = lib.licenses.mit;
    sourceProvenance = [ lib.sourceTypes.fromSource ];
    platforms = lib.platforms.linux; # Metal backend is macOS-only, out of scope
    mainProgram = "ds4";
  };
})
