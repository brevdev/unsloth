#!/bin/bash

# Unsloth Notebook Downloader Script
# Downloads popular Unsloth notebooks from GitHub

set -e

NOTEBOOKS_DIR="/workspace/custom-notebooks"
UNSLOTH_REPO="https://raw.githubusercontent.com/unslothai/unsloth/main"

echo "=== Unsloth Notebook Downloader ==="
echo "Downloading notebooks to: $NOTEBOOKS_DIR"

mkdir -p "$NOTEBOOKS_DIR"
cd "$NOTEBOOKS_DIR"

# Common Unsloth notebooks to download
declare -A NOTEBOOKS=(
    ["llama3-8b-finetuning.ipynb"]="$UNSLOTH_REPO/examples/Llama-3-8b_Alpaca.ipynb"
    ["mistral-7b-finetuning.ipynb"]="$UNSLOTH_REPO/examples/Mistral-7b_Alpaca.ipynb"
    ["qwen2-7b-finetuning.ipynb"]="$UNSLOTH_REPO/examples/Qwen2-7b_Alpaca.ipynb"
    ["codellama-7b-finetuning.ipynb"]="$UNSLOTH_REPO/examples/CodeLlama-7b_Python.ipynb"
    ["phi3-mini-finetuning.ipynb"]="$UNSLOTH_REPO/examples/Phi-3-mini_4k_instruct.ipynb"
    ["gemma-7b-finetuning.ipynb"]="$UNSLOTH_REPO/examples/Gemma-7b_Alpaca.ipynb"
)

# Download notebooks
for notebook in "${!NOTEBOOKS[@]}"; do
    url="${NOTEBOOKS[$notebook]}"
    echo "Downloading $notebook from $url"
    
    if curl -L -f -o "$notebook" "$url"; then
        echo "✓ Successfully downloaded $notebook"
    else
        echo "✗ Failed to download $notebook"
    fi
done

# Download additional example notebooks if available
echo ""
echo "=== Additional Examples ==="

# Try to download other common examples
declare -A ADDITIONAL_EXAMPLES=(
    ["fine-tune-any-llm.ipynb"]="$UNSLOTH_REPO/examples/Fine_tune_any_LLM.ipynb"
    ["conversation-training.ipynb"]="$UNSLOTH_REPO/examples/Conversation_training.ipynb"
    ["multimodal-training.ipynb"]="$UNSLOTH_REPO/examples/Multimodal_training.ipynb"
)

for notebook in "${!ADDITIONAL_EXAMPLES[@]}"; do
    url="${ADDITIONAL_EXAMPLES[$notebook]}"
    echo "Attempting to download $notebook from $url"
    
    if curl -L -f -o "$notebook" "$url" 2>/dev/null; then
        echo "✓ Successfully downloaded $notebook"
    else
        echo "⚠ Could not download $notebook (may not exist)"
    fi
done

echo ""
echo "=== Download Complete ==="
echo "Available notebooks:"
ls -la "$NOTEBOOKS_DIR"/*.ipynb 2>/dev/null || echo "No notebooks found"

echo ""
echo "To use a specific notebook, set the NOTEBOOK_PATH environment variable:"
echo "export NOTEBOOK_PATH=/workspace/custom-notebooks/llama3-8b-finetuning.ipynb"
echo ""
echo "Note: Official Unsloth example notebooks are already available in:"
echo "/workspace/unsloth-notebooks/"