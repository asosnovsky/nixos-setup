{ lib
, stdenv
, fetchFromGitHub
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
  backendMakeFlags = {
    cpu = [ ];

    rocm = [
      "ROCM_ARCH=${rocmArch}"
      # Append store include/lib paths to the upstream ROCm flags.
      "ROCM_CFLAGS=-O3 -ffast-math -g -fno-finite-math-only -pthread -D__HIP_PLATFORM_AMD__ -Wno-unused-command-line-argument --offload-arch=${rocmArch} ${rocmIncludeFlags}"
      "ROCM_LDLIBS=-lm -pthread ${rocmLinkFlags} -lhipblas -lhipblaslt"
    ];

    cuda = [
      "NVCC=${lib.getExe' cudaPackages.cuda_nvcc "nvcc"}"
      "CUDA_HOME=${cudaPackages.cuda_nvcc}"
      # Replace upstream's hardcoded /usr/local/cuda + sbsa-linux (aarch64)
      # paths with the nixpkgs cudart/cublas store paths.
      "CUDA_LDLIBS=-lm -Xcompiler -pthread ${cudaLinkFlags} -lcudart -lcublas"
    ] ++ lib.optional (cudaArch != null) "CUDA_ARCH=${cudaArch}";
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
    lib.optionals (backend == "rocm") [ rocmPackages.clr ]
    ++ lib.optionals (backend == "cuda") [ cudaPackages.cuda_nvcc ];

  buildInputs =
    lib.optionals (backend == "rocm") rocmInputs
    ++ lib.optionals (backend == "cuda") [
      cudaPackages.cuda_cudart
      cudaPackages.libcublas
    ];

  makeFlags = backendMakeFlags;
  buildFlags = [ buildTarget ];

  installPhase = ''
    runHook preInstall
    install -Dm755 -t "$out/bin" ds4 ds4-server ds4-bench ds4-eval ds4-agent
    runHook postInstall
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
