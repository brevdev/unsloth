#!/bin/bash

# Unsloth Jupyter Enhancement Script
# This script enhances the official Unsloth Docker environment with additional automation

set -e

echo "=== Unsloth Enhancement Script ==="
echo "Current working directory: $(pwd)"
echo "User: $(whoami)"
echo "Home: $HOME"

# The official unsloth image runs as the 'unsloth' user
# and already has a complete environment set up

# Check GPU availability
echo "=== GPU Information ==="
if command -v nvidia-smi &> /dev/null; then
    nvidia-smi --query-gpu=name,memory.total,memory.free --format=csv,noheader,nounits
else
    echo "No NVIDIA GPU detected or nvidia-smi not available"
fi

# Check if we need to download a notebook
if [ ! -z "$NOTEBOOK_URL" ]; then
    echo "=== Downloading Notebook ==="
    echo "Downloading notebook from: $NOTEBOOK_URL"
    mkdir -p /workspace/custom-notebooks
    cd /workspace/custom-notebooks
    curl -L -o "$(basename "$NOTEBOOK_URL")" "$NOTEBOOK_URL"
    export NOTEBOOK_PATH="/workspace/custom-notebooks/$(basename "$NOTEBOOK_URL")"
    echo "Downloaded notebook to: $NOTEBOOK_PATH"
fi

# Create additional directories for organization
mkdir -p /workspace/{custom-notebooks,data,models,outputs}

echo "=== Environment Information ==="
echo "Model: ${MODEL_NAME:-Not specified}"
echo "Notebook: ${NOTEBOOK_PATH:-Not specified}"
echo "Auto-start notebook: ${AUTO_START_NOTEBOOK:-false}"
echo "Jupyter port: ${JUPYTER_PORT:-8888}"
echo "HuggingFace token: ${HF_TOKEN:+Set}"
echo "Wandb API key: ${WANDB_API_KEY:+Set}"

# Set HuggingFace token if provided
if [ ! -z "$HF_TOKEN" ]; then
    echo "Setting HuggingFace token..."
    export HUGGINGFACE_HUB_TOKEN="$HF_TOKEN"
    huggingface-cli login --token "$HF_TOKEN" --add-to-git-credential
fi

# Set Wandb API key if provided
if [ ! -z "$WANDB_API_KEY" ]; then
    echo "Setting Wandb API key..."
    export WANDB_API_KEY="$WANDB_API_KEY"
fi

# Pre-download model if specified
if [ ! -z "$MODEL_NAME" ]; then
    echo "=== Pre-loading Model ==="
    echo "Pre-loading model: $MODEL_NAME"
    python -c "
from transformers import AutoTokenizer
try:
    print('Downloading tokenizer...')
    tokenizer = AutoTokenizer.from_pretrained('$MODEL_NAME', cache_dir='${MODEL_CACHE_DIR}')
    print('Tokenizer downloaded successfully')
except Exception as e:
    print(f'Could not download tokenizer: {e}')
"
fi

echo "=== Starting Enhanced Unsloth Environment ==="
echo "The official Unsloth Jupyter environment will start shortly..."
echo "Access URL: http://localhost:${JUPYTER_PORT:-8888}"
echo ""
echo "Available notebooks:"
echo "- Official examples: /workspace/unsloth-notebooks/"
echo "- Custom notebooks: /workspace/custom-notebooks/"
echo "- Your work: /workspace/work/"

# The official unsloth image has its own startup sequence
# We'll let it handle the Jupyter startup
# This script is mainly for setup and enhancement