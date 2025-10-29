#!/bin/bash
# Mount NVIDIA driver libraries dynamically
# This script finds and mounts NVIDIA driver libraries at container startup
# It works across different NVIDIA driver versions and CUDA versions

set -e

echo "Detecting NVIDIA driver libraries..."

# Common NVIDIA library paths on the host
NVIDIA_LIB_PATHS=(
  "/usr/lib/x86_64-linux-gnu"
  "/usr/lib64"
  "/opt/nvidia/lib64"
)

# Look for libcuda.so in common locations
LIBCUDA_PATH=""
for path in "${NVIDIA_LIB_PATHS[@]}"; do
  if [ -f "$path/libcuda.so.1" ]; then
    LIBCUDA_PATH="$path"
    echo "✓ Found NVIDIA libraries at: $LIBCUDA_PATH"
    break
  fi
done

if [ -z "$LIBCUDA_PATH" ]; then
  echo "⚠ Warning: Could not find libcuda.so.1 in standard locations"
  echo "  Checked: ${NVIDIA_LIB_PATHS[*]}"
  echo "  GPU may not be accessible"
  exit 0
fi

# Create symlinks for NVIDIA libraries if they don't exist
mkdir -p /usr/lib/x86_64-linux-gnu

# Function to safely link NVIDIA libraries
link_nvidia_lib() {
  local lib_name=$1
  local source="$LIBCUDA_PATH/$lib_name"
  local target="/usr/lib/x86_64-linux-gnu/$lib_name"
  
  if [ -f "$source" ] && [ ! -f "$target" ]; then
    ln -s "$source" "$target" 2>/dev/null || true
    echo "  Linked: $lib_name"
  fi
}

# Link essential NVIDIA libraries
link_nvidia_lib "libcuda.so.1"
link_nvidia_lib "libcuda.so"
link_nvidia_lib "libnvidia-ml.so.1"
link_nvidia_lib "libnvidia-fatbinaryloader.so"

# Try to find and link fatbinaryloader with version
for lib in "$LIBCUDA_PATH"/libnvidia-fatbinaryloader.so*; do
  if [ -f "$lib" ]; then
    basename=$(basename "$lib")
    ln -s "$LIBCUDA_PATH/$basename" "/usr/lib/x86_64-linux-gnu/$basename" 2>/dev/null || true
  fi
done

echo "✓ NVIDIA libraries configured"

# Verify libcuda.so is accessible
if python3 -c "import ctypes; ctypes.CDLL('/usr/lib/x86_64-linux-gnu/libcuda.so.1')" 2>/dev/null; then
  echo "✓ libcuda.so.1 is loadable by Python"
else
  echo "⚠ Warning: libcuda.so.1 could not be loaded"
fi
