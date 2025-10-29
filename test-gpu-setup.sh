#!/bin/bash
# GPU Test Script - Verify all fixes are working

set -e

echo "🔧 Unsloth GPU & Jupyter Fix Verification"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

CONTAINER_NAME="unsloth-notebook"
ERRORS=0

echo "📋 Step 1: Check container is running..."
if ! docker ps | grep -q "$CONTAINER_NAME"; then
    echo -e "${RED}✗ Container $CONTAINER_NAME not running${NC}"
    echo "  Start with: docker-compose up -d"
    ERRORS=$((ERRORS+1))
else
    echo -e "${GREEN}✓ Container is running${NC}"
fi

if [ $ERRORS -gt 0 ]; then
    exit 1
fi

echo ""
echo "🔍 Step 2: Check LD_LIBRARY_PATH is set..."
LD_LIB_PATH=$(docker exec $CONTAINER_NAME bash -c 'echo $LD_LIBRARY_PATH' || echo "")
if [ -z "$LD_LIB_PATH" ]; then
    echo -e "${RED}✗ LD_LIBRARY_PATH is empty${NC}"
    ERRORS=$((ERRORS+1))
else
    echo -e "${GREEN}✓ LD_LIBRARY_PATH is set:${NC}"
    echo "  $LD_LIB_PATH"
fi

echo ""
echo "🔍 Step 3: Check CUDA libraries exist..."
if docker exec $CONTAINER_NAME test -f /usr/local/cuda-12.8/lib64/libcuda.so.1; then
    echo -e "${GREEN}✓ CUDA libraries found${NC}"
else
    echo -e "${RED}✗ CUDA libraries not found${NC}"
    ERRORS=$((ERRORS+1))
fi

echo ""
echo "🔍 Step 4: Check PyTorch CUDA support..."
PYTORCH_OUTPUT=$(docker exec $CONTAINER_NAME python3 -c "
import torch
print('PyTorch version:', torch.__version__)
print('CUDA available:', torch.cuda.is_available())
if torch.cuda.is_available():
    print('Device:', torch.cuda.get_device_name(0))
    print('GPU Memory:', round(torch.cuda.get_device_properties(0).total_memory / 1e9, 1), 'GB')
else:
    print('Device: CPU only')
")
echo "$PYTORCH_OUTPUT"

if echo "$PYTORCH_OUTPUT" | grep -q "CUDA available: True"; then
    echo -e "${GREEN}✓ PyTorch GPU support is working!${NC}"
else
    echo -e "${RED}✗ PyTorch GPU support NOT working${NC}"
    ERRORS=$((ERRORS+1))
fi

echo ""
echo "🔍 Step 5: Check Unsloth GPU support..."
UNSLOTH_OUTPUT=$(docker exec $CONTAINER_NAME python3 -c "
try:
    from unsloth import FastModel
    print('✓ Unsloth imported successfully')
except NotImplementedError as e:
    print('✗ Unsloth error:', str(e))
except Exception as e:
    print('✗ Unexpected error:', str(e))
" 2>&1)
echo "$UNSLOTH_OUTPUT"

if echo "$UNSLOTH_OUTPUT" | grep -q "✓"; then
    echo -e "${GREEN}✓ Unsloth GPU support is available!${NC}"
else
    echo -e "${RED}✗ Unsloth GPU support has issues${NC}"
    ERRORS=$((ERRORS+1))
fi

echo ""
echo "🔍 Step 6: Check Jupyter is running..."
if docker exec $CONTAINER_NAME curl -s http://localhost:8888/api > /dev/null; then
    echo -e "${GREEN}✓ Jupyter Lab is responding${NC}"
else
    echo -e "${YELLOW}⚠ Jupyter Lab not responding yet (it may still be starting)${NC}"
fi

echo ""
echo "=========================================="
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✅ All checks passed! GPU setup is working!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Open Jupyter: http://localhost:8888"
    echo "2. Create a new notebook"
    echo "3. Run: from unsloth import FastModel"
    echo "4. Start training on GPU! 🚀"
else
    echo -e "${RED}❌ Some checks failed. See issues above.${NC}"
    echo ""
    echo "Troubleshooting:"
    echo "1. Restart container: docker-compose down && docker-compose up -d"
    echo "2. Check logs: docker-compose logs unsloth-jupyter"
    echo "3. See: docs/GPU_SETUP_FIX.md"
fi

echo ""
exit $ERRORS
