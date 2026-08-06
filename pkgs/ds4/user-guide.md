# ds4 (DwarfStar) — user guide

A from-source build of [`antirez/ds4`](https://github.com/antirez/ds4), a local
inference engine for **DeepSeek V4 Flash/PRO**. This is a short operational
guide; see the [upstream README](https://github.com/antirez/ds4) for the full
documentation (server API, agent, distributed inference, tuning, etc.).

## What's installed

The package builds for a chosen GPU backend (`cpu`, `rocm`, or `cuda`) and
installs these binaries:

| Binary | What it does |
|---|---|
| `ds4` | Interactive CLI chat / one-shot `-p "..."` |
| `ds4-server` | OpenAI/Anthropic/Responses-compatible HTTP API |
| `ds4-agent` | Native terminal coding agent (alpha) |
| `ds4-bench` | Throughput benchmarking |
| `ds4-eval` | Capability/regression eval harness |
| `ds4-download-model` | Helper to fetch GGUF weights (see below) |

There is **no graphical UI**. `ds4-server` exposes a URL you can point an
OpenAI-compatible client at.

## 1. Get the weights

Weights are **not** packaged. They live at the project's Hugging Face repos
([`antirez/deepseek-v4-gguf`](https://huggingface.co/antirez/deepseek-v4-gguf)
for DeepSeek V4, [`antirez/GLM-5.2-GGUF`](https://huggingface.co/antirez/GLM-5.2-GGUF)
and [`unsloth/GLM-5.2-GGUF`](https://huggingface.co/unsloth/GLM-5.2-GGUF) for
GLM 5.2) — public, MIT, no token needed — and only these custom GGUFs work, not
arbitrary DeepSeek/GLM GGUFs.

`ds4-download-model` writes into `./gguf` and links `./ds4flash.gguf` in the
current directory (override the root with `DS4_HOME`, or the gguf dir with
`DS4_GGUF_DIR`):

```sh
# DeepSeek V4 Flash (0731 checkpoints)
ds4-download-model ds4f-q2          # ~81 GB, the pick for 96/128 GB machines
ds4-download-model ds4f-q2-q4      # ~98 GB, last 6 expert layers at q4
ds4-download-model ds4f-q4         # ~153 GB, for >=256 GB machines
ds4-download-model ds4f-mxfp4      # ~156 GB, native MXFP4 (Metal/CUDA)
ds4-download-model ds4f-dspark     # ~6 GB, optional DSpark speculative draft

# DeepSeek V4 PRO (512 GB / distributed)
ds4-download-model pro-q2-imatrix          # single-file PRO q2
ds4-download-model pro-q4-split            # both halves of PRO Q4 split

# GLM 5.2
ds4-download-model glm-unsloth-q4         # Unsloth UD-Q4_K_XL, 11 shards
ds4-download-model glm-antirez-iq2xxs     # routed IQ2_XXS, reduced-memory
ds4-download-model glm-antirez-q2         # routed Q2_K, ~262 GB
ds4-download-model glm-antirez-q4         # routed Q4_K, ~434 GB

ds4-download-model --help                 # full target list
```

Pick by machine memory: `ds4f-q2` (96/128 GB), `ds4f-q4` (>=256 GB),
`pro-*` (512 GB / distributed), `glm-*` (per-target sizes above). The small
Flash quants download via `curl`; the MXFP4, PRO, and GLM files use the `hf`
CLI (bundled in the package via `huggingface-hub` + `hf-xet`), which
`ds4-download-model` puts on its PATH automatically.

## 2. Run it

```sh
# interactive chat (defaults to ./ds4flash.gguf in the current dir)
ds4

# explicit model path
ds4 -m /path/to/gguf/DeepSeek-V4-Flash-IQ2XXS-...-imatrix-0731.gguf

# DSpark speculative decoding (greedy only; needs the ds4f-dspark support GGUF)
ds4 -m ./ds4flash.gguf \
  --dspark --mtp ./gguf/DeepSeek-V4-Flash-DSpark-support-0731.gguf --temp 0

# GLM 5.2 (experimental greedy MTP via --glm-mtp)
ds4 -m gguf/GLM-5.2-UD-IQ2_XXS_RoutedIQ2XXS_blk78Q2K.gguf --glm-mtp-timing --temp 0

# HTTP server on the LAN
ds4-server -m ./ds4flash.gguf \
  --ctx 100000 --kv-disk-dir ./kv --kv-disk-space-mb 8192 --host 0.0.0.0
```

Then point a client at `http://<host>:8000/v1` (endpoints: `/v1/chat/completions`,
`/v1/messages`, `/v1/responses`, ...). Use `--cors` for browser clients.

## Backend notes

- **rocm** targets a specific GPU arch (default `gfx1151`, AMD Strix Halo). At
  runtime the user needs `/dev/kfd` + render-node access, and large models need
  the GTT memory kernel params from upstream's `STRIXHALO.md`. On Strix Halo,
  export `HSA_ENABLE_SDMA=0` (SDMA is buggy on its unified memory).
- **cuda** is unfree (CUDA closure) and needs an NVIDIA driver at runtime.
- **cpu** is a reference/debug path only — not for production inference.

## Maintenance

This tracks upstream `main` (no releases). To bump, set `rev` in `default.nix`
and refresh `hash`. Binaries are built per-host (`-march=native`), so build each
GPU variant on its target host. See `default.nix`'s header comment for details.
