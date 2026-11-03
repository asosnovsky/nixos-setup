{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  ninja,
  pkg-config,
  autoPatchelfHook,
  rocmPackages,
  # "rocm" builds the gfx1151 engine. "cpu" is the same tree without the GPU
  # backend, so the recipe can be checked on a machine with no AMD card.
  backend ? "rocm",
  rocmArch ? "gfx1151",
}:

# llama.cpp, pinned to the first release that carries DFlash2 drafters
# (v0.8.0, 2026-10-28). nixpkgs only has v0.6.0 in the unstable input and an
# older tree in the stable one, and DFlash2 landed upstream after both — hence
# this package. Built for the Framework Desktop iGPU (Strix Halo, gfx1151).
#
# To bump: set `version` and `rev`, refresh `hash` with
# `nix-prefetch-url --unpack https://github.com/ggml-org/llama.cpp/archive/refs/tags/vX.Y.Z.tar.gz`
# then `nix hash convert --to sri <hash>`. Check the release notes for a new
# `--spec-type` before assuming a drafter still loads.

assert lib.elem backend [
  "cpu"
  "rocm"
];

let
  rocmInputs = [
    rocmPackages.clr
    rocmPackages.rocm-runtime
    rocmPackages.hipblas
    rocmPackages.rocblas
  ];
in
stdenv.mkDerivation {
  pname = "llama-cpp-halo" + lib.optionalString (backend == "cpu") "-cpu";
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
  ];

  buildInputs = lib.optionals (backend == "rocm") rocmInputs;

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
  ];

  doCheck = false;

  meta = {
    description = "llama.cpp server (DFlash2 speculative decoding) for AMD Strix Halo (gfx1151)";
    homepage = "https://github.com/ggml-org/llama.cpp";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "llama-server";
  };
}
