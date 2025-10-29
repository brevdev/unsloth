#!/bin/bash

# Setup script for first-time users
# This script helps set up the Unsloth Docker environment

set -e

echo "🦥 Unsloth Docker Framework Setup"
echo "=================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if we're in the right directory
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}Error: docker-compose.yml not found. Please run this script from the project root.${NC}"
    exit 1
fi

echo "Setting up your Unsloth environment..."
echo ""

# 1. Check dependencies
echo -e "${BLUE}1. Checking dependencies...${NC}"

if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed${NC}"
    echo "Please install Docker: https://docs.docker.com/get-docker/"
    exit 1
else
    echo -e "${GREEN}✅ Docker found${NC}"
fi

# Check for Docker Compose (both new and legacy formats)
if docker compose version &> /dev/null; then
    echo -e "${GREEN}✅ Docker Compose found (docker compose)${NC}"
    export DOCKER_COMPOSE_CMD="docker compose"
elif command -v docker-compose &> /dev/null; then
    echo -e "${GREEN}✅ Docker Compose found (docker-compose)${NC}"
    export DOCKER_COMPOSE_CMD="docker-compose"
else
    echo -e "${RED}❌ Docker Compose is not available${NC}"
    echo "Please install Docker Compose or update Docker to a version that includes 'docker compose'"
    exit 1
fi

# Check NVIDIA support
if command -v nvidia-smi &> /dev/null; then
    echo -e "${GREEN}✅ NVIDIA GPU detected${NC}"
    
    # Check if NVIDIA Container Toolkit is installed
    if docker run --rm --gpus all nvidia/cuda:11.8-base-ubuntu20.04 nvidia-smi &> /dev/null; then
        echo -e "${GREEN}✅ NVIDIA Container Toolkit working${NC}"
    else
        echo -e "${YELLOW}⚠️  NVIDIA Container Toolkit may not be properly configured${NC}"
        echo "You might need to install it: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html"
    fi
else
    echo -e "${YELLOW}⚠️  No NVIDIA GPU detected (CPU-only mode)${NC}"
fi

# 2. Create directories
echo ""
echo -e "${BLUE}2. Creating directories...${NC}"

directories=("work" "custom-notebooks" "data" "models" "outputs")
for dir in "${directories[@]}"; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        echo -e "${GREEN}✅ Created $dir/${NC}"
    else
        echo -e "${YELLOW}📁 $dir/ already exists${NC}"
    fi
done

# 3. Configuration info
echo ""
echo -e "${BLUE}3. Configuration...${NC}"
echo -e "${GREEN}✅ No configuration files needed - everything has defaults${NC}"
echo ""
echo -e "${YELLOW}Optional: Set environment variables before starting:${NC}"
echo "  export JUPYTER_PASSWORD=mypassword"
echo "  export HF_TOKEN=hf_xxxxx"
echo "  export WANDB_API_KEY=xxxxx"
echo ""
echo "Or just start with defaults (passwordless Jupyter):"
echo "  docker compose up -d"

# 4. Make scripts executable
echo ""
echo -e "${BLUE}4. Setting up scripts...${NC}"

if [ -d "scripts" ]; then
    chmod +x scripts/*.sh
    echo -e "${GREEN}✅ Made scripts executable${NC}"
fi

# 5. Test Docker setup
echo ""
echo -e "${BLUE}5. Testing Docker setup...${NC}"

if docker info &> /dev/null; then
    echo -e "${GREEN}✅ Docker daemon is running${NC}"
else
    echo -e "${RED}❌ Docker daemon is not running${NC}"
    echo "Please start Docker and try again"
    exit 1
fi

# 6. Show next steps
echo ""
echo -e "${GREEN}🎉 Setup complete!${NC}"
echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. Start the environment:"
echo -e "   ${YELLOW}docker compose up -d${NC}"
echo ""
echo "2. Access Jupyter Lab:"
echo -e "   ${YELLOW}http://localhost:8888${NC}"
echo ""
echo "3. Test GPU detection:"
echo -e "   ${YELLOW}Open work/test-gpu-cuda.ipynb and run all cells${NC}"
echo ""
echo "4. Read the documentation:"
echo -e "   ${YELLOW}cat README.md${NC}"

echo ""
echo "Happy fine-tuning! 🦥"