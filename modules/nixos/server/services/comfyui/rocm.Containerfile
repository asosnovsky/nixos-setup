FROM rocm/pytorch:rocm7.2.1_ubuntu24.04_py3.12_pytorch_release_2.9.1

# ─── ROCm environment for gfx1151 (Strix Halo) ───────────────────────────
ENV HSA_OVERRIDE_GFX_VERSION=11.5.1
ENV HSA_ENABLE_SDMA=0
ENV ROCBLAS_USE_HIPBLASLT=1
ENV PYTORCH_HIP_ALLOC_CONF=expandable_segments:False

# ─── Clone ComfyUI ────────────────────────────────────────────────────────
ARG COMFYUI_COMMIT=master
ENV COMFYUI_PATH=/workspace/ComfyUI

RUN git clone https://github.com/comfyanonymous/ComfyUI "$COMFYUI_PATH" \
    && cd "$COMFYUI_PATH" \
    && if [ "$COMFYUI_COMMIT" != "master" ]; then git checkout "$COMFYUI_COMMIT"; fi

# ─── Install ComfyUI requirements ─────────────────────────────────────────
RUN pip install --no-cache-dir -r "$COMFYUI_PATH/requirements.txt"

# ─── Custom nodes ─────────────────────────────────────────────────────────

# ComfyUI-Manager
RUN git clone https://github.com/ltdrdata/ComfyUI-Manager \
        "$COMFYUI_PATH/custom_nodes/ComfyUI-Manager" \
    && pip install --no-cache-dir \
        -r "$COMFYUI_PATH/custom_nodes/ComfyUI-Manager/requirements.txt"

# WAN 2.1 video nodes
RUN git clone https://github.com/kijai/ComfyUI-WanVideoWrapper \
        "$COMFYUI_PATH/custom_nodes/ComfyUI-WanVideoWrapper" \
    && pip install --no-cache-dir \
        -r "$COMFYUI_PATH/custom_nodes/ComfyUI-WanVideoWrapper/requirements.txt" \
    || true

# Video Helper Suite
RUN git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite \
        "$COMFYUI_PATH/custom_nodes/ComfyUI-VideoHelperSuite" \
    && pip install --no-cache-dir \
        -r "$COMFYUI_PATH/custom_nodes/ComfyUI-VideoHelperSuite/requirements.txt" \
    || true

# ─── Model directories ────────────────────────────────────────────────────
RUN mkdir -p \
    "$COMFYUI_PATH/models/checkpoints" \
    "$COMFYUI_PATH/models/vae" \
    "$COMFYUI_PATH/models/loras" \
    "$COMFYUI_PATH/models/unet" \
    "$COMFYUI_PATH/models/clip" \
    "$COMFYUI_PATH/models/controlnet" \
    "$COMFYUI_PATH/output"

WORKDIR "$COMFYUI_PATH"
EXPOSE 8188

COPY init.sh /init.sh
RUN chmod +x /init.sh
ENTRYPOINT ["/init.sh"]
