#!/usr/bin/env bash
# init.sh – runs inside the ComfyUI Docker container
#
# 1. Checks whether each custom node directory exists.
# 2. If a node is missing, it is cloned from its repository
#    and its Python dependencies are installed via pip.
# 3. Finally, the script hands control over to the ComfyUI server
#    (python main.py ...).

set -euo pipefail

# The base directory for ComfyUI – exported in the Dockerfile.
COMFYUI_PATH=${COMFYUI_PATH:-/workspace/ComfyUI}

# Helper to clone and install a node only if it does not already exist.
install_node() {
  local repo_url=$1
  local node_dir=$2
  local req_file=$3

  if [ ! -d "$node_dir" ]; then
    echo "Cloning $repo_url into $node_dir ..."
    git clone "$repo_url" "$node_dir"

    if [ -f "$req_file" ]; then
      echo "Installing dependencies for $node_dir ..."
      pip install --no-cache-dir -r "$req_file"
    else
      echo "No requirements file found for $node_dir; skipping pip install."
    fi
  else
    echo "$node_dir already exists; skipping clone."
  fi
}

# 1️⃣ ComfyUI‑Manager
install_node "https://github.com/ltdrdata/ComfyUI-Manager" \
  "$COMFYUI_PATH/custom_nodes/ComfyUI-Manager" \
  "$COMFYUI_PATH/custom_nodes/ComfyUI-Manager/requirements.txt"

# 2️⃣ WAN 2.1 Video Wrapper
install_node "https://github.com/kijai/ComfyUI-WanVideoWrapper" \
  "$COMFYUI_PATH/custom_nodes/ComfyUI-WanVideoWrapper" \
  "$COMFYUI_PATH/custom_nodes/ComfyUI-WanVideoWrapper/requirements.txt"

# 3️⃣ Video Helper Suite
install_node "https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite" \
  "$COMFYUI_PATH/custom_nodes/ComfyUI-VideoHelperSuite" \
  "$COMFYUI_PATH/custom_nodes/ComfyUI-VideoHelperSuite/requirements.txt"

# 4️⃣ Start the ComfyUI server
echo "Starting ComfyUI..."
exec python "$COMFYUI_PATH/main.py" \
  --listen 0.0.0.0 \
  --port 8188 \
  --use-pytorch-cross-attention
