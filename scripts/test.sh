#!/bin/bash
# Basic tests for Unsloth Docker setup

set -e

echo "Running Unsloth Docker Tests..."
echo "================================"

# Test 1: Check required files exist
echo "Test 1: Checking required files..."
required_files=(
    "docker-compose.yml"
    "scripts/entrypoint-passwordless.sh"
    "configs/unsloth-sudoers"
    "work/test-gpu-cuda.ipynb"
    "README.md"
)

for file in "${required_files[@]}"; do
    if [ ! -f "$file" ]; then
        echo "  ✗ Missing: $file"
        exit 1
    fi
done
echo "  ✓ All required files present"

# Test 2: Check shell script syntax
echo "Test 2: Checking shell script syntax..."
for script in scripts/*.sh; do
    if ! bash -n "$script" 2>/dev/null; then
        echo "  ✗ Syntax error in $script"
        exit 1
    fi
done
echo "  ✓ All scripts have valid syntax"

# Test 3: Validate docker-compose.yml
echo "Test 3: Validating docker-compose configuration..."
if command -v docker &> /dev/null; then
    if docker compose version &> /dev/null; then
        DOCKER_COMPOSE="docker compose"
    elif command -v docker-compose &> /dev/null; then
        DOCKER_COMPOSE="docker-compose"
    else
        echo "  ⚠ Docker Compose not available - skipping validation"
        DOCKER_COMPOSE=""
    fi
    
    if [ -n "$DOCKER_COMPOSE" ]; then
        if ! $DOCKER_COMPOSE config > /dev/null 2>&1; then
            echo "  ✗ Invalid docker-compose.yml"
            exit 1
        fi
        echo "  ✓ docker-compose.yml is valid"
    fi
else
    echo "  ⚠ Docker not available - skipping validation"
fi

# Test 4: Check sudoers file permissions
echo "Test 4: Checking sudoers file permissions..."
perms=$(stat -c "%a" configs/unsloth-sudoers)
if [ "$perms" != "440" ]; then
    echo "  ✗ Wrong permissions on sudoers file: $perms (should be 440)"
    exit 1
fi
echo "  ✓ Sudoers file has correct permissions"

# Test 5: Check directory structure
echo "Test 5: Checking directory structure..."
required_dirs=(
    "work"
    "data"
    "models"
    "outputs"
    "scripts"
    "configs"
)

for dir in "${required_dirs[@]}"; do
    if [ ! -d "$dir" ]; then
        echo "  ✗ Missing directory: $dir"
        exit 1
    fi
done
echo "  ✓ All required directories present"

echo ""
echo "================================"
echo "✅ All tests passed!"
echo ""
echo "To start Unsloth:"
echo "  docker compose up -d"

