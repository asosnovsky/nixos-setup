{
  description = "colibrì — run GLM-5.2 (744B MoE) on a consumer machine with ~25 GB RAM";

  # Reproducibility: these inputs track a branch, so torch/numpy/etc. float across
  # rebuilds. For deterministic builds run `nix flake lock` once and COMMIT the
  # generated flake.lock (it pins each input to a commit SHA). (#D2)
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { self
    , nixpkgs
    , flake-utils
    ,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };

        # Python with the packages needed by the offline converter tools
        pythonEnv = pkgs.python3.withPackages (
          ps:
            with ps; [
              torch
              safetensors
              huggingface-hub
              numpy
              tokenizers
              datasets
            ]
        );

        colibri = pkgs.stdenv.mkDerivation {
          pname = "colibri";
          version = "1.0";
          src = ./.;

          nativeBuildInputs = with pkgs; [ makeWrapper ];

          buildInputs = with pkgs; [
            gcc
            gmp
          ];

          # python3 is needed by checkPhase: `make test-c` shells out to
          # `python3 tools/run_tests.py` (see c/Makefile, PYTHON ?= python3).
          nativeCheckInputs = with pkgs; [ python3 ];

          # Use x86-64-v3 (AVX2) for a portable binary; override with ARCH=native for local builds
          ARCH =
            if pkgs.stdenv.hostPlatform.isx86_64
            then "x86-64-v3"
            else "native";

          buildPhase = ''
            runHook preBuild
            make -C c glm ARCH="$ARCH"
            runHook postBuild
          '';

          installPhase = ''
            runHook preInstall

            # Self-contained layout under $out/lib/colibri that mirrors the
            # source tree `coli` runs in (see the path-resolution logic at the
            # top of c/coli): the engine, the coli CLI script, the support
            # modules it imports (openai_server.py, resource_plan.py,
            # doctor.py), and tools/ all sit next to each other.
            mkdir -p $out/lib/colibri/tools $out/bin
            cp c/glm             $out/lib/colibri/glm
            cp c/coli            $out/lib/colibri/coli
            chmod +x $out/lib/colibri/coli
            cp c/openai_server.py c/resource_plan.py c/doctor.py c/version.py \
              $out/lib/colibri/
            cp -r c/tools/*      $out/lib/colibri/tools/

            # $out/bin holds the user-facing entry points.
            ln -s ../lib/colibri/glm $out/bin/glm

            # Wrap coli: point it at the bundled engine (COLI_ENGINE) so it is
            # found by default, and at the module dir (PYTHONPATH) so
            # `import openai_server` / `resource_plan` / `doctor` resolve.
            makeWrapper ${pythonEnv}/bin/python $out/bin/coli \
              --add-flags "$out/lib/colibri/coli" \
              --set-default COLI_ENGINE "$out/lib/colibri/glm" \
              --set PYTHONPATH "$out/lib/colibri:${pythonEnv}/${pkgs.python3.sitePackages}"
            runHook postInstall
          '';

          checkPhase = ''
            runHook preCheck
            cd c
            make test-c
            cd ..
            runHook postCheck
          '';

          doCheck = true;

          meta = with pkgs.lib; {
            description = "Run GLM-5.2 (744B MoE) on a consumer machine with ~25 GB RAM";
            homepage = "https://github.com/JustVugg/colibri";
            license = licenses.asl20;
            platforms = with platforms; linux ++ darwin;
            mainProgram = "coli";
          };
        };

        # ROCm/HIP variant: same package as `colibri`, plus the optional GPU
        # expert tier built for AMD via the engine's HIP=1 path (see c/Makefile).
        # Tuned for the Framework Desktop's Radeon 8060S/8050S iGPU == gfx1151.
        # Linux-only (HIP=1 errors out on non-Linux in the Makefile).
        #
        #   nix build .#colibri-rocm
        #   COLI_MODEL=/nvme/glm52_i4 CUDA_EXPERT_GB=auto nix run .#colibri-rocm -- chat
        #
        # If a gfx1151 kernel misbehaves on your ROCm version, run with
        #   HSA_OVERRIDE_GFX_VERSION=11.0.0
        colibri-rocm = colibri.overrideAttrs (old: {
          pname = "colibri-rocm";

          buildInputs =
            old.buildInputs
            ++ (with pkgs.rocmPackages; [ clr rocm-runtime hipblas ]);

          buildPhase = ''
            runHook preBuild
            make -C c glm \
              ARCH="$ARCH" \
              HIP=1 \
              HIP_ARCH="gfx1151" \
              ROCM_HOME="${pkgs.rocmPackages.clr}" \
              HIPCC="${pkgs.rocmPackages.clr}/bin/hipcc"
            runHook postBuild
          '';

          # test-c would relink the engine WITHOUT HIP=1 (clobbering the GPU
          # build), and the GPU path needs real hardware — so skip the suite.
          doCheck = false;

          meta = old.meta // { platforms = pkgs.lib.platforms.linux; };
        });
      in
      {
        packages =
          {
            default = colibri;
            inherit colibri;
          }
          # Only expose the ROCm package on Linux (HIP build is Linux-only).
          // pkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
            inherit colibri-rocm;
          };

        apps = {
          default = {
            type = "app";
            program = pkgs.lib.getExe colibri;
          };
          glm = {
            type = "app";
            program = "${colibri}/share/colibri/glm";
          };
        };

        formatter = pkgs.alejandra;

        devShells.default = pkgs.mkShell {
          inputsFrom = [ colibri ];

          packages = with pkgs; [
            pythonEnv
            gcc
            gnumake
            clang-tools # clangd / clang-tidy for IDE support
            pkg-config
          ];

          shellHook = ''
            echo "🐦 colibrì dev shell"
            echo "  gcc: $(gcc --version | head -1)"
            echo "  python: $(python3 --version)"
            echo ""
            echo "Build the engine:   make -C c glm"
            echo "Run the converter:  python c/coli convert --model /path/to/glm52_i4"
            echo "Chat:               COLI_MODEL=/path/to/glm52_i4 ./c/glm ..."
          '';
        };
      }
    );
}
