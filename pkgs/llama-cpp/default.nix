{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  ninja,
  pkg-config,
  autoPatchelfHook,
  rocmPackages,
  cuda_packages,
  # "rocm" builds the gfx1151 engine (Strix Halo). "cuda" builds for NVIDIA
  # GPUs (e.g., RTX 3060). "cpu" is the same tree without a GPU backend.
  backend ? "rocm",
  rocmArch ? "gfx1151",
}:

# llama.cpp, pinned to the first release that carries DFlash2 drafters
# (v0.8.0, 2026-10-28). nixpkgs only has v0.6.0 in the unstable input and an
# older tree in the stable one, and DFlash2 landed upstream after both — hence
# this package. Supports ROCm (AMD, Strix Halo) and CUDA (NVIDIA, RTX 3060).
#
# To bump: set `version` and `rev`, refresh `hash` with
# `nix-prefetch-url --unpack https://github.com/ggml-org/llama.cpp/archive/refs/tags/vX.Y.Z.tar.gz`
# then `nix hash convert --to sri <hash>`. Check the release notes for a new
# `--spec-type` before assuming a drafter still loads.

assert lib.elem backend [
  "cpu"
  "rocm"
  "cuda"
];

let
  rocmInputs = [
    rocmPackages.clr
    rocmPackages.rocm-runtime
    rocmPackages.hipblas
    rocmPackages.rocblas
  ];
  cudaInputs = [
    cuda_packages.cudatoolkit
    cuda_packages.cudnn
  ];
in
stdenv.mkDerivation {
  pname = "llama-cpp" + lib.optionalString (backend == "rocm") "-halo" + lib.optionalString (backend == "cuda") "-cuda" + lib.optionalString (backend == "cpu") "-cpu";
  version = "0.8.0";

  src = fetchFromGitHub {
    owner = "ggml-org";
    repo = "llama.cpp";
    tag = "v0.8.0";
    hash = "sha256-WQAtD8Hos6fEtgPQId7nZiLGyP4asAMKJYEXZid1nqc=";
  };

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
  ]
  ++ lib.optionals (backend == "rocm") [
    autoPatchelfHook
    # Provides clang++ and the HIP headers; llama.cpp wants ROCm's own clang.
    rocmPackages.clr
  ]
  ++ lib.optionals (backend == "cuda") [
    autoPatchelfHook
    cuda_packages.cudatoolkit
  ];

  buildInputs = lib.optionals (backend == "rocm") rocmInputs ++ lib.optionals (backend == "cuda") cudaInputs;

  # The web UI is a prebuilt asset downloaded at build time, which the sandbox
  # cannot do. The API does not need it.
  cmakeFlags = [
    (lib.cmakeBool "GGML_NATIVE" false)
    (lib.cmakeBool "BUILD_SHARED_LIBS" false)
    (lib.cmakeBool "LLAMA_BUILD_SERVER" true)
    (lib.cmakeBool "LLAMA_BUILD_TESTS" false)
    (lib.cmakeBool "LLAMA_BUILD_EXAMPLES" false)
    (lib.cmakeBool "LLAMA_BUILD_APP" false)
    (lib.cmakeBool "LLAMA_BUILD_UI" false)
    (lib.cmakeBool "LLAMA_USE_PREBUILT_UI" false)
    (lib.cmakeBool "LLAMA_OPENSSL" false)
    # Upstream reads these from git, which the release tarball does not carry.
    (lib.cmakeFeature "LLAMA_BUILD_NUMBER" "31309")
    (lib.cmakeFeature "LLAMA_BUILD_COMMIT" "8642541b2")
  ]
  ++ lib.optionals (backend == "rocm") [
    (lib.cmakeBool "GGML_HIP" true)
    (lib.cmakeFeature "CMAKE_HIP_COMPILER" "${rocmPackages.clr.hipClangPath}/clang++")
    (lib.cmakeFeature "CMAKE_HIP_ARCHITECTURES" rocmArch)
  ]
  ++ lib.optionals (backend == "cuda") [
    (lib.cmakeBool "GGML_CUDA" true)
    (lib.cmakeFeature "CMAKE_CUDA_COMPILER" "${cuda_packages.cudatoolkit}/bin/nvcc")
  ];

  doCheck = false;

  meta = {
    description = "llama.cpp server (DFlash2 speculative decoding) with ROCm/CUDA support";
    homepage = "https://github.com/ggml-org/llama.cpp";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "llama-server";
  };
}
