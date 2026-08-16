# ollama — local LLM inference server, version-pinned ahead of nixpkgs.
#
# Derived from nixpkgs master's ollama package.nix at the 0.32.13 commit
# (which introduced the FetchContent-based llama.cpp build, Vulkan/ROCm/CUDA
# backends, and spirv-headers). Updated to 0.32.14.
#
# UPDATING THIS PACKAGE
# =====================
# 1. Set `version` to the new tag (without "v").
# 2. Set `src.hash` to `lib.fakeHash` and attempt a build.
#    Copy the "got: sha256-..." value from the Nix error output.
# 3. Set `vendorHash` to `lib.fakeHash` and attempt a build again.
#    Copy the "got: sha256-..." value from the Nix error output.
# 4. Check whether LLAMA_CPP_VERSION changed in the new release tag.
#    If so, also update `llamaCppVersion` and `llamaCppSrc.hash`.

{ lib
, buildGoModule
, fetchFromGitHub
, buildEnv
, makeBinaryWrapper
, stdenv
, addDriverRunpath
, cmake
, gitMinimal
, clblast
, libdrm
, rocmPackages
, rocmGpuTargets ? rocmPackages.clr.localGpuTargets or (rocmPackages.clr.gpuTargets or [ ])
, cudaPackages
, cudaArches ? cudaPackages.flags.realArches or [ ]
, autoAddDriverRunpath
, apple-sdk_15
, vulkan-tools
, vulkan-headers
, vulkan-loader
, spirv-headers
, shaderc
, ccache
, versionCheckHook
, writableTmpDirAsHomeHook
, config
, # one of `[ null false "rocm" "cuda" "vulkan" ]`
  acceleration ? null
,
}:

assert builtins.elem acceleration [
  null
  false
  "rocm"
  "cuda"
  "vulkan"
];

let
  validateFallback = lib.warnIf (config.rocmSupport && config.cudaSupport)
    (lib.concatStrings [
      "both `nixpkgs.config.rocmSupport` and `nixpkgs.config.cudaSupport` are enabled, "
      "but they are mutually exclusive; falling back to cpu"
    ])
    (!(config.rocmSupport && config.cudaSupport));
  shouldEnable =
    mode: fallback: (acceleration == mode) || (fallback && acceleration == null && validateFallback);

  rocmRequested = shouldEnable "rocm" config.rocmSupport;
  cudaRequested = shouldEnable "cuda" config.cudaSupport;
  vulkanRequested = acceleration == "vulkan";

  enableRocm = rocmRequested && stdenv.hostPlatform.isLinux;
  enableCuda = cudaRequested && stdenv.hostPlatform.isLinux;
  enableVulkan = vulkanRequested && stdenv.hostPlatform.isLinux;

  rocmLibs = [
    rocmPackages.clr
    rocmPackages.hipblas-common
    rocmPackages.hipblas
    rocmPackages.rocblas
    rocmPackages.rocsolver
    rocmPackages.rocsparse
    rocmPackages.rocm-device-libs
    rocmPackages.rocm-smi
  ];
  rocmPath = buildEnv {
    name = "rocm-path";
    paths = rocmLibs;
  };

  cudaLibs = [
    cudaPackages.cuda_cudart
    cudaPackages.libcublas
    cudaPackages.cccl
  ];

  vulkanLibs = [
    vulkan-headers
    vulkan-loader
  ];

  cudaMajorVersion = lib.versions.major cudaPackages.cuda_cudart.version;

  cudaToolkit = buildEnv {
    name = "cuda-merged-${cudaMajorVersion}";
    paths = map lib.getLib cudaLibs ++ [
      (lib.getOutput "static" cudaPackages.cuda_cudart)
      (lib.getBin (cudaPackages.cuda_nvcc.__spliced.buildHost or cudaPackages.cuda_nvcc))
    ];
    ignoreCollisions = true;
  };

  cudaPath = lib.removeSuffix "-${cudaMajorVersion}" cudaToolkit;

  # Since v0.30, llama.cpp is consumed via CMake FetchContent rather than
  # vendored in-tree. Pre-stage the pin so the FetchContent step uses our
  # copy instead of trying to clone over the network in the sandbox.
  # Check LLAMA_CPP_VERSION in the ollama source tree when bumping.
  llamaCppVersion = "b10434";
  llamaCppSrc = fetchFromGitHub {
    owner = "ggml-org";
    repo = "llama.cpp";
    tag = llamaCppVersion;
    hash = "sha256-Sz0kW1q91YzdrKbZUqMbFJ0DLZrzARSGheUrtCKcoQo=";
  };

  wrapperOptions = [
    "--suffix LD_LIBRARY_PATH : '${addDriverRunpath.driverLink}/lib'"
  ]
  ++ lib.optionals enableRocm [
    "--suffix LD_LIBRARY_PATH : '${rocmPath}/lib'"
    "--set-default HIP_PATH '${rocmPath}'"
  ]
  ++ lib.optionals enableCuda [
    "--suffix LD_LIBRARY_PATH : '${lib.makeLibraryPath (map lib.getLib cudaLibs)}'"
  ]
  ++ lib.optionals enableVulkan [
    "--suffix LD_LIBRARY_PATH : '${lib.makeLibraryPath (map lib.getLib vulkanLibs)}'"
    "--set-default OLLAMA_VULKAN '1'"
  ];
  wrapperArgs = builtins.concatStringsSep " " wrapperOptions;

  goBuild =
    if enableCuda then
      buildGoModule.override { stdenv = cudaPackages.backendStdenv; }
    else if enableRocm then
      buildGoModule.override { inherit (rocmPackages) stdenv; }
    else if enableVulkan then
      buildGoModule.override { inherit (vulkan-tools) stdenv; }
    else
      buildGoModule;

  inherit (lib) licenses platforms maintainers;
in
goBuild (finalAttrs: {
  pname = "ollama";
  version = "0.32.14";

  src = fetchFromGitHub {
    owner = "ollama";
    repo = "ollama";
    tag = "v${finalAttrs.version}";
    hash = "sha256-wvEG7L61gYI63pfHZ9UnTVQh8QMG3wHMfxEBeshtIKQ=";
  };

  vendorHash = "sha256-HMwoaFBMbpoy8f0I+O+i7kIa9BslLu3FcVWeaIOkpvs=";
  proxyVendor = true;

  env =
    lib.optionalAttrs enableRocm
      {
        ROCM_PATH = rocmPath;
        CLBlast_DIR = "${clblast}/lib/cmake/CLBlast";
        HIP_PATH = rocmPath;
        CFLAGS = "-Wno-c++17-extensions -I${rocmPath}/include";
        CXXFLAGS = "-Wno-c++17-extensions -I${rocmPath}/include";
      }
    // lib.optionalAttrs enableCuda { CUDA_PATH = cudaPath; }
    // lib.optionalAttrs enableVulkan { VULKAN_SDK = shaderc.bin; };

  nativeBuildInputs = [
    cmake
    gitMinimal
  ]
  ++ lib.optionals enableRocm (
    rocmLibs
      ++ [
      rocmPackages.llvm.bintools
    ]
  )
  ++ lib.optionals enableCuda [ cudaPackages.cuda_nvcc ]
  ++ lib.optionals (enableRocm || enableCuda) [
    makeBinaryWrapper
    autoAddDriverRunpath
  ]
  ++ lib.optionals enableVulkan [
    ccache
    spirv-headers
  ];

  buildInputs =
    lib.optionals enableRocm (rocmLibs ++ [ libdrm ])
    ++ lib.optionals enableCuda cudaLibs
    ++ lib.optionals stdenv.hostPlatform.isDarwin [ apple-sdk_15 ]
    ++ lib.optionals enableVulkan vulkanLibs;

  postPatch = ''
    substituteInPlace version/version.go \
      --replace-fail 0.0.0 '${finalAttrs.version}'

    rm cmd/launch/*_test.go

    rm -r app

    if [[ ${llamaCppVersion} != $(cat LLAMA_CPP_VERSION) ]]; then
      echo "llama-cpp version mismatch, expected ${llamaCppVersion}, but found $(cat LLAMA_CPP_VERSION)"
      exit 1
    fi
    cp -r ${llamaCppSrc} $TMPDIR/llama-cpp-src
    chmod -R +w $TMPDIR/llama-cpp-src
    ( cd $TMPDIR/llama-cpp-src && \
      cmake -DPATCH_DIR=$NIX_BUILD_TOP/source/llama/compat \
        -P $NIX_BUILD_TOP/source/llama/compat/apply-patch.cmake )
  '';

  overrideModAttrs = _: _: {
    preBuild = "";
  };

  preBuild =
    let
      removeSMPrefix =
        str:
        let
          matched = builtins.match "sm_(.*)" str;
        in
        if matched == null then str else builtins.head matched;

      cudaArchitectures = builtins.concatStringsSep ";" (map removeSMPrefix cudaArches);
      rocmTargets = builtins.concatStringsSep ";" rocmGpuTargets;

      rocmMajorVersion = lib.versions.major rocmPackages.clr.version;
      rocmMinorVersion = lib.versions.minor rocmPackages.clr.version;
      llamaBackend =
        if enableCuda then
          "cuda_v${cudaMajorVersion}"
        else if enableRocm then
          "rocm_v${rocmMajorVersion}_${rocmMinorVersion}"
        else if enableVulkan then
          "vulkan"
        else
          "";

      cmakeFlagsCudaArchitectures = lib.optionalString enableCuda "-DCMAKE_CUDA_ARCHITECTURES='${cudaArchitectures}'";
      cmakeFlagsRocmTargets = lib.optionalString enableRocm "-DAMDGPU_TARGETS='${rocmTargets}'";
      cmakeFlagsBackend = lib.optionalString
        (
          llamaBackend != ""
        ) "-DOLLAMA_LLAMA_BACKENDS=${llamaBackend}";
    in
    ''
      ${lib.optionalString enableVulkan ''
        export CMAKE_PREFIX_PATH="${spirv-headers}''${CMAKE_PREFIX_PATH:+:$CMAKE_PREFIX_PATH}"
        export NIX_CFLAGS_COMPILE="-isystem ${spirv-headers}/include $NIX_CFLAGS_COMPILE"
      ''}
      cmake -B build \
        -DCMAKE_SKIP_BUILD_RPATH=ON \
        -DCMAKE_BUILD_WITH_INSTALL_RPATH=ON \
        -DFETCHCONTENT_SOURCE_DIR_LLAMA_CPP="$TMPDIR/llama-cpp-src" \
        -DOLLAMA_MLX_BACKENDS="" \
        $cmakeFlags \
        ${cmakeFlagsCudaArchitectures} \
        ${cmakeFlagsRocmTargets} \
        ${cmakeFlagsBackend}

      cmake --build build -j $NIX_BUILD_CORES
    '';

  preFixup = lib.optionalString stdenv.hostPlatform.isLinux ''
    find $out/lib/ollama -type f \( -name '*.so' -o -name '*.so.*' \) \
      -exec patchelf --shrink-rpath --allowed-rpath-prefixes /nix/store {} +
  '';

  postInstall = ''
    mkdir -p $out/lib
    cp -r build/lib/ollama $out/lib/
  '';

  postFixup =
    lib.optionalString (enableRocm || enableCuda) ''
      wrapProgram "$out/bin/ollama" ${wrapperArgs}
    '';

  ldflags = [
    "-X=github.com/ollama/ollama/version.Version=${finalAttrs.version}"
    "-X=github.com/ollama/ollama/server.mode=release"
  ];

  __darwinAllowLocalNetworking = true;

  sandboxProfile = lib.optionalString stdenv.hostPlatform.isDarwin ''
    (allow file-read* (subpath "/System/Library/Extensions"))
    (allow iokit-open (iokit-user-client-class "AGXDeviceUserClient"))
  '';

  checkFlags =
    let
      skippedTests = [
        "TestPushHandler/unauthorized_push"
        "TestPiRun_InstallAndWebSearchLifecycle"
      ];
    in
    [ "-skip=^${builtins.concatStringsSep "$|^" skippedTests}$" ];

  doInstallCheck = true;
  nativeInstallCheckInputs = [
    versionCheckHook
    writableTmpDirAsHomeHook
  ];
  versionCheckKeepEnvironment = "HOME";

  passthru = {
    inherit llamaCppSrc llamaCppVersion;
  };

  meta = {
    description =
      "Get up and running with large language models locally"
      + lib.optionalString rocmRequested ", using ROCm for AMD GPU acceleration"
      + lib.optionalString cudaRequested ", using CUDA for NVIDIA GPU acceleration"
      + lib.optionalString vulkanRequested ", using Vulkan for generic GPU acceleration";
    homepage = "https://github.com/ollama/ollama";
    changelog = "https://github.com/ollama/ollama/releases/tag/v${finalAttrs.version}";
    license = licenses.mit;
    platforms =
      if (rocmRequested || cudaRequested || vulkanRequested) then platforms.linux else platforms.unix;
    mainProgram = "ollama";
    maintainers = with maintainers; [ prusnak ];
    broken = stdenv.buildPlatform != stdenv.hostPlatform;
  };
})
