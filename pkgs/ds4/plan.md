# Plan: Package `antirez/ds4` (DwarfStar) as a Nix package

This document is a self-contained implementation plan for adding the
[`antirez/ds4`](https://github.com/antirez/ds4) inference engine ("DwarfStar")
to this repo's custom package set under `pkgs/ds4`. It is written so another
agent (or future me) can pick it up cold.

## Goal

A single, **backend-parameterized** derivation at `pkgs/ds4/default.nix` that
builds ds4 from source for a chosen GPU backend, wired into the repo's overlay.
Backends in scope:

- **ROCm** (`make strix-halo`, AMD Strix Halo / `gfx1151`).
- **CUDA** (`make cuda-generic`, or `make cuda CUDA_ARCH=sm_NN` for an explicit
  arch).
- **CPU** (`make cpu`) as the safe default and cheapest smoke build.

(Which backend is installed where is intentionally deferred to the final
**Host wiring & deployment** section.)

Decisions already made by the repo owner:

1. **Parameterize** the package by target/backend (one `default.nix`, selected
   via a `backend` argument).
2. **Build per host** — i.e. compile natively with `-march=native`/`-mcpu=native`
   (the upstream Makefile default). We are *not* pinning a portable baseline
   `-march`. This means the resulting store paths are CPU-specific; that's
   acceptable here. (Implication: don't expect these variants to be cache-shared
   across differing CPUs, and the CUDA/ROCm variants generally must be built on a
   machine with the toolchain anyway.)
3. **Track `main`** — pin the current `main` HEAD commit (below). No upstream
   releases/tags exist.

## Upstream facts (verified from the repo on 2026-06-30)

- **License:** MIT.
- **Pinned commit (`main` HEAD at planning time):**
  `80ebbc396aee40eedc1d829222f3362d10fa4c6c`
- **Build system:** hand-written `Makefile`, no `install` target. Languages:
  C (C99), CUDA, Objective-C (Metal, macOS only), Metal shaders, some C++.
- **Binaries produced (all backends):** `ds4`, `ds4-server`, `ds4-bench`,
  `ds4-eval`, `ds4-agent`.
- **Metal is macOS-only** and irrelevant to our NixOS Linux hosts.

### Makefile behavior that matters for packaging

From the upstream `Makefile` (Linux branch, i.e. `uname -s` != `Darwin`):

```make
CC ?= cc
NATIVE_CPU_FLAG ?= -march=native            # Linux; -mcpu=native on Darwin
CFLAGS ?= -O3 -ffast-math -g $(NATIVE_CPU_FLAG) -Wall -Wextra -std=c99
CFLAGS += -D_GNU_SOURCE -fno-finite-math-only
LDLIBS ?= -lm -pthread

# CUDA
CUDA_HOME ?= /usr/local/cuda
NVCC ?= $(CUDA_HOME)/bin/nvcc
CUDA_ARCH ?=                                 # empty unless overridden
NVCCFLAGS ?= -O3 -g -lineinfo --use_fast_math $(NVCC_ARCH_FLAGS) \
             -Xcompiler $(NATIVE_CPU_FLAG) -Xcompiler -pthread
CUDA_LDLIBS ?= -lm -Xcompiler -pthread \
               -L$(CUDA_HOME)/targets/sbsa-linux/lib -L$(CUDA_HOME)/lib64 \
               -lcudart -lcublas

# ROCm
HIPCC ?= $(shell command -v hipcc 2>/dev/null || echo /opt/rocm/bin/hipcc)
ROCM_ARCH ?= gfx1151
ROCM_CFLAGS ?= -O3 -ffast-math -g -fno-finite-math-only -pthread \
               -D__HIP_PLATFORM_AMD__ -Wno-unused-command-line-argument \
               --offload-arch=$(ROCM_ARCH)
ROCM_LDLIBS ?= -lm -pthread -lhipblas -lhipblaslt
```

Relevant phony targets (Linux):

- `make cuda-generic` → `$(MAKE) -B ds4 ds4-server ds4-bench ds4-eval ds4-agent CUDA_ARCH=native`
- `make cuda-spark`   → same but `CUDA_ARCH=` (empty; DGX Spark/GB10)
- `make cuda CUDA_ARCH=sm_NN` → explicit arch (errors if `CUDA_ARCH` empty)
- `make strix-halo` (alias `make rocm`) → rebuilds the 5 binaries with
  `CORE_OBJS="ds4.o ds4_distributed.o ds4_ssd.o ds4_rocm.o"`,
  `CFLAGS="… -DDS4_ROCM_BUILD"`, `DS4_LINK="$(HIPCC) $(ROCM_CFLAGS)"`,
  `DS4_LINK_LIBS="$(ROCM_LDLIBS)"`.
- `make cpu` → CPU-only reference build (`-DDS4_NO_GPU`), no GPU libs. Useful
  as a cheap CI/portable smoke build.
- `make test` → builds `ds4_test`, `ds4_agent_test`, `ds4-eval`, a dot-product
  test, and runs them. The CUDA path links tests with `nvcc`.

Key gotchas:

1. **No `install` target** → we must write our own `installPhase` copying the 5
   binaries into `$out/bin`.
2. **`-march=native`** is on by default. Per decision #2 we keep it (build per
   host). For the optional `cpu` smoke variant built on the remote builder, the
   resulting binary is CPU-specific to the builder — fine for a smoke test, but
   do **not** distribute a `cpu` variant to heterogeneous machines without
   overriding `NATIVE_CPU_FLAG`.
3. **CUDA library paths** are hardcoded to `/usr/local/cuda/...` and an
   `sbsa-linux` (aarch64) target dir. Under Nix we must point `CUDA_HOME`/`NVCC`
   at the nixpkgs CUDA toolkit and likely override `CUDA_LDLIBS` so the `-L`
   paths resolve inside the store. Expect to set `NVCC`, `CUDA_HOME`, and a
   corrected `CUDA_LDLIBS` via `makeFlags`.
4. **ROCm** finds `hipcc` via `command -v hipcc`, so having `rocmPackages.clr`
   (provides `hipcc`) on `PATH` (`nativeBuildInputs`) is enough. `ROCM_ARCH`
   defaults to `gfx1151` (exactly the Strix Halo target). The backend uses
   **rocWMMA**; on Ubuntu upstream notes the distro packages miss
   `rocwmma/internal/` headers (see `STRIXHALO.md`). Under Nix,
   `rocmPackages.rocwmma` should provide the complete header tree — verify
   during implementation (ROCm phase).
5. **`-ffast-math` / `-fno-finite-math-only`** are upstream defaults; leave
   them. Standard `fortify`/`strip` Nix hardening should be fine but watch for
   warnings; can disable hardening flags if the build complains.
6. Runtime: on Linux the binaries are self-contained (Metal `.metal` runtime
   files are macOS-only). GGUF model weights and `download_model.sh` are a
   **runtime** concern, NOT packaged. The agent/server accept `--chdir` and
   `-m <path>` for model selection.

## Repo conventions (how packages are added here)

See `pkgs/ABOUTME.md`. The pattern is:

1. Create `pkgs/<name>/default.nix` (standard derivation; `callPackage`-style
   function taking its inputs as arguments).
2. Register in the overlay in `modules/core/default.nix`:
   ```nix
   nixpkgs.overlays = [
     (final: _prev: {
       grok-cli = final.callPackage ../../pkgs/grok-cli { };
       # add ds4 entries here
     })
     # ...
   ];
   ```
3. Reference as `pkgs.<name>` anywhere in the flake / host modules.
4. Optionally expose as a flake output under `packages` in `flake.nix`
   (see the existing `grok-cli = lib.pkgs.${system}.grok-cli;` line).

`pkgs/grok-cli/default.nix` is the existing reference example (but note it is a
prebuilt binary using `stdenvNoCC` + `fetchurl`; **ds4 is build-from-source and
must use `stdenv.mkDerivation` + `fetchFromGitHub`**).

---

## Implementation phases

### Phase 1 — Source pinning
- [ ] Write the `fetchFromGitHub` `src` with:
  - `owner = "antirez"; repo = "ds4";`
  - `rev = "80ebbc396aee40eedc1d829222f3362d10fa4c6c";` (current `main` HEAD;
    bump as desired since we track `main`).
  - `hash` — start with `lib.fakeHash`, run a build, copy the real SRI hash
    from the error. (Equivalent to the `nix-prefetch`/`fakeHash` flow noted in
    `pkgs/ABOUTME.md`.)

### Phase 2 — Core derivation skeleton (`pkgs/ds4/default.nix`)
Parameterized function. Sketch (to be refined during implementation):

```nix
{ lib
, stdenv
, fetchFromGitHub
, rocmPackages
, cudaPackages
# backend selects the build target / toolchain
, backend ? "cpu"   # one of "cpu" | "rocm" | "cuda"
, cudaArch ? null    # e.g. "sm_89"; null => cuda-generic (CUDA_ARCH=native)
, rocmArch ? "gfx1151"
}:

assert lib.elem backend [ "cpu" "rocm" "cuda" ];

stdenv.mkDerivation (finalAttrs: {
  pname = "ds4";
  version = "unstable-2026-06-17";          # date of pinned commit
  src = fetchFromGitHub { /* Phase 1 */ };

  enableParallelBuilding = true;

  # nativeBuildInputs / buildInputs / makeFlags / buildPhase vary by backend
  # (ROCm / CUDA / CPU phases).

  installPhase = ''
    runHook preInstall
    install -Dm755 -t "$out/bin" ds4 ds4-server ds4-bench ds4-eval ds4-agent
    runHook postInstall
  '';

  meta = {
    description = "DeepSeek V4 Flash/PRO local inference engine (DwarfStar)";
    homepage = "https://github.com/antirez/ds4";
    license = lib.licenses.mit;
    sourceProvenance = [ lib.sourceTypes.fromSource ];
    platforms = lib.platforms.linux;        # Metal/macOS out of scope
    mainProgram = "ds4";
  };
})
```

- [ ] Implement the skeleton with a `let buildTarget = { cpu = "cpu"; rocm =
      "strix-halo"; cuda = if cudaArch == null then "cuda-generic" else "cuda"; }`
      style mapping, and a per-backend `makeFlags`/`buildFlags`.
- [ ] Keep `-march=native` (do **not** override `NATIVE_CPU_FLAG`) per decision #2.

### Phase 3 — ROCm backend
- [ ] `nativeBuildInputs`: `rocmPackages.clr` (provides `hipcc`).
- [ ] `buildInputs`: `rocmPackages` libs needed by `ds4_rocm.cu` and link flags
      (`-lhipblas -lhipblaslt`): at least `clr`, `hipblas`, `hipblaslt`,
      `rocblas`, `rocwmma`, plus header-only `hipcub`/`rocprim` as required.
- [ ] Build: `make strix-halo` (or pass the equivalent `makeFlags`). `ROCM_ARCH`
      defaults to `gfx1151`; allow override via `rocmArch` arg.
- [ ] **Verify rocWMMA headers**: ensure `rocwmma/internal/*` resolves from the
      nixpkgs `rocwmma` package (upstream `STRIXHALO.md` warns the Ubuntu pkgs
      are incomplete). If missing, add the include path or the right package.
- [ ] May need `ROCM_PATH`/include/lib flags so `hipcc` finds the store-located
      ROCm libs; adjust `ROCM_CFLAGS`/`ROCM_LDLIBS` via `makeFlags` if needed.

### Phase 4 — CUDA backend
- [ ] `nativeBuildInputs`: `cudaPackages.cuda_nvcc`.
- [ ] `buildInputs`: `cudaPackages.cuda_cudart`, `cudaPackages.libcublas`.
- [ ] Override the hardcoded CUDA paths via `makeFlags`:
  - `CUDA_HOME = ...` / `NVCC = "${cudaPackages.cuda_nvcc}/bin/nvcc"`,
  - a corrected `CUDA_LDLIBS` that points `-L` at the nixpkgs cudart/cublas
    `lib` dirs instead of `/usr/local/cuda/...` and `sbsa-linux` (that path is
    aarch64; an x86_64 target should use `lib64`/store libs).
- [ ] Build target: `cuda-generic` (`CUDA_ARCH=native`) by default, or `cuda`
      with an explicit `cudaArch` (preferred for reproducibility / when the
      build host differs from the GPU host).
- [ ] CUDA is unfree → the package's closure is unfree. Keep `meta.license =
      lib.licenses.mit` for the source itself, but be aware `allowUnfree` is
      required to build/realize this variant.

### Phase 5 — CPU backend (default)
- [ ] `make cpu`; no GPU inputs. Cheapest build, good for a portable smoke test
      and as the safe default `backend = "cpu"`.
- [ ] Add `doInstallCheck` running `$out/bin/ds4 --help` (only meaningful for
      the CPU variant; GPU variants may require a device at runtime, so guard
      or skip the check for them).

### Phase 6 — Overlay wiring (`modules/core/default.nix`)
Add to the existing `nixpkgs.overlays` first entry:
```nix
(final: _prev: {
  grok-cli = final.callPackage ../../pkgs/grok-cli { };
  ds4      = final.callPackage ../../pkgs/ds4 { };                 # cpu default
  ds4-rocm = final.callPackage ../../pkgs/ds4 { backend = "rocm"; };
  ds4-cuda = final.callPackage ../../pkgs/ds4 { backend = "cuda"; };
})
```
- [ ] Confirm `rocmPackages` / `cudaPackages` resolve via `callPackage` (they
      are top-level attrs in nixpkgs, so they will).

### Phase 7 — Flake output (optional)
- [ ] In `flake.nix` `packages` output, alongside `grok-cli`, optionally expose:
      `ds4 = lib.pkgs.${system}.ds4;` (CPU variant — buildable on any system).
      The GPU variants are awkward as generic flake outputs (need toolchains),
      so leave them overlay-only unless wanted.

### Phase 8 — Validation
Order by cheapness / portability:
- [ ] `nix build .#ds4` (or via a throwaway `nix-build -E`) — CPU variant,
      builds on the default builder. Resolve the `src` hash here (Phase 1).
- [ ] `nix build` the ROCm variant (build on a machine with the ROCm toolchain).
      Smoke: `ds4 --help`.
- [ ] `nix build` the CUDA variant (build on a machine with the CUDA toolchain).
      Smoke: `ds4 --help`.
- [ ] `nixpkgs-fmt` the new/edited Nix files (repo uses it as a pre-commit
      hook and devshell formatter).
- [ ] Update `pkgs/ABOUTME.md` contents table with the new `ds4` entries.

### Phase 9 — Docs / cleanup
- [ ] Add a short header comment in `pkgs/ds4/default.nix` (like `grok-cli`)
      explaining backends, the `-march=native` "build per host" choice, the
      `main`-tracking pin, and how to bump (`rev` + refresh `hash`).
- [ ] Delete or keep this `plan.md` (suggest keeping until implementation lands,
      then optionally remove).

## Risks / unknowns to resolve during implementation

- **CUDA path overrides**: the Makefile's `CUDA_LDLIBS` hardcodes
  `targets/sbsa-linux/lib` (aarch64) + `/usr/local/cuda`. On x86_64 nixpkgs
  this must be replaced. Highest-risk part of the CUDA backend.
- **rocWMMA internal headers** under nixpkgs (ROCm phase) — verify availability.
- **Hardening flags**: `-ffast-math` + Nix default hardening may produce
  warnings; if the build breaks, selectively disable (`hardeningDisable`).
- **Build-per-host vs. binary cache**: with `-march=native`, store paths are
  CPU-specific; ensure builds happen on (or for) the right host.

---

## Host wiring & deployment (do this last)

All host-specific assignment and system enablement lives here, after the
package itself builds and is wired into the overlay.

Hosts are defined in `flake.nix` under `nixosConfigurations`. System-level
packages for a host are typically added in the host's module (or a shared
module it imports); locate where each host declares `environment.systemPackages`
/ module package lists and add the appropriate `pkgs.ds4-*` there.

### `hl-fwdesk` — ROCm
- Module: `hosts/hl-fwdesk.nix` (uses
  `framework-desktop-amd-ai-max-300-series`); the box is AMD Ryzen AI Max 300
  (Strix Halo, `gfx1151`) — exactly the ROCm/`make strix-halo` target.
- [ ] Add `pkgs.ds4-rocm` to the host's package list.
- [ ] Confirm ROCm is enabled on the host (drivers, `hardware.graphics` /
      ROCm runtime) before expecting the GPU path to work.
- [ ] System enablement required to *run* it (not part of the package), per
      `STRIXHALO.md`:
  - `/dev/kfd` + DRM render-node access (user in `render`/`video` groups).
  - GTT memory kernel params so the full 128 GB is GPU-visible:
    `amd_iommu=off amdgpu.gttsize=126976 ttm.pages_limit=32505856
    ttm.page_pool_size=32505856` (in `boot.kernelParams`).

### `hl-bigbox1` — CUDA
- Module: `hosts/hl-bigbox1.nix`. Host has an NVIDIA GPU.
- [ ] Add `pkgs.ds4-cuda` to the host's package list.
- [ ] Confirm the exact NVIDIA GPU/arch to decide between `cuda-generic`
      (`CUDA_ARCH=native`) and a pinned `CUDA_ARCH=sm_NN`
      (e.g. `sm_86`/`sm_89`/`sm_90`). Pinning is preferred when the build host
      differs from the GPU host.
- [ ] Ensure `nixpkgs.config.allowUnfree` (and CUDA driver/`hardware.graphics`
      support) is set for this host — the CUDA closure is unfree.
- [ ] The configured remote builder `root@bigbox1.lab.internal` is x86_64 and
      may double as the native CUDA build host (convenient, avoids
      cross-CPU `-march=native` mismatches).
