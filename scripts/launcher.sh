#!/bin/bash

# Unsloth Docker Launcher Script
# Easy launcher for different Unsloth configurations

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"


# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Detect dry-run flag
DRY_RUN=false
for arg in "$@"; do
    if [[ "$arg" == "--dry-run" ]]; then
        DRY_RUN=true
        break
    fi
done

print_usage() {
    echo -e "${BLUE}Unsloth Docker Launcher${NC}"
    echo ""
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  start [config]     Start Unsloth notebook environment"
    echo "  stop               Stop running containers"
    echo "  logs               Show container logs"
    echo "  download           Download popular Unsloth notebooks"
    echo "  build              Build the Docker image"
    echo "  clean              Clean up containers and images"
    echo "  list               List available configurations"
    echo ""
    echo "Available configurations:"
    echo "  default            Default Jupyter environment"
    echo "  llama3-8b          Llama 3 8B fine-tuning"
    echo "  mistral-7b         Mistral 7B fine-tuning"
    echo "  qwen2-7b           Qwen 2 7B fine-tuning"
    echo "  codellama-7b       CodeLlama 7B fine-tuning"
    echo ""
    echo "Examples:"
    echo "  $0 start                    # Start with default configuration"
    echo "  $0 start llama3-8b         # Start with Llama 3 8B configuration"
    echo "  $0 download                # Download popular notebooks"
    echo "  $0 logs                    # Show logs"
}

check_requirements() {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}Error: Docker is not installed${NC}"
        exit 1
    fi

    # Check for Docker Compose (both new and legacy formats)
    if docker compose version &> /dev/null; then
        export DOCKER_COMPOSE_CMD="docker compose"
    elif command -v docker-compose &> /dev/null; then
        export DOCKER_COMPOSE_CMD="docker-compose"
    else
        echo -e "${RED}Error: Docker Compose is not available${NC}"
        echo -e "${RED}Please install Docker Compose or update Docker to a version that includes 'docker compose'${NC}"
        exit 1
    fi

    if ! docker info &> /dev/null; then
        echo -e "${RED}Error: Docker daemon is not running${NC}"
        exit 1
    fi
}

check_nvidia_support() {
    if [ "$DRY_RUN" = true ]; then
        echo -e "${YELLOW}⚠ Skipping NVIDIA GPU check (dry-run mode)${NC}"
        return 0
    fi
    if command -v nvidia-docker &> /dev/null; then
        echo -e "${GREEN}✓ NVIDIA GPU support detected (nvidia-docker present)${NC}"
        return 0
    fi
    # Try to detect CUDA version from nvidia-smi
    cuda_version=$(nvidia-smi | grep 'CUDA Version' | awk '{print $9}' | head -1)
    cuda_tag="11.8"
    if [[ "$cuda_version" =~ ^[0-9]+\.[0-9]+$ ]]; then
        cuda_tag="$cuda_version"
    fi
    # Try running a test container with detected CUDA version
    if docker run --rm --gpus all nvidia/cuda:${cuda_tag}-base-ubuntu20.04 nvidia-smi &> /dev/null; then
        echo -e "${GREEN}✓ NVIDIA GPU support detected (docker --gpus with CUDA $cuda_tag works)${NC}"
        return 0
    fi
    # Fallback: check if docker info shows NVIDIA runtime
    if docker info | grep -i 'Runtimes:' | grep -q nvidia; then
        echo -e "${GREEN}✓ NVIDIA runtime detected in Docker (but test container failed)${NC}"
        return 0
    fi
    echo -e "${YELLOW}⚠ No NVIDIA GPU support detected${NC}"
    echo -e "${YELLOW}  The container will run in CPU-only mode${NC}"
    echo -e "${YELLOW}  Diagnostics:${NC}"
    echo -e "${YELLOW}  - nvidia-smi output:${NC}"
    nvidia_smi_out=$(nvidia-smi 2>&1 || true)
    echo -e "${YELLOW}$nvidia_smi_out${NC}"
    echo -e "${YELLOW}  - Tried: docker run --rm --gpus all nvidia/cuda:${cuda_tag}-base-ubuntu20.04 nvidia-smi${NC}"
    echo -e "${YELLOW}  - Docker info runtimes:${NC}"
    docker info | grep -i 'Runtimes:'
    return 1
}

start_service() {
    local config=${1:-default}
    
    echo -e "${BLUE}Starting Unsloth with configuration: $config${NC}"
    
    cd "$PROJECT_DIR"
    
    # Check for specific configuration
    if [ "$config" != "default" ] && [ -f "configs/${config}.env" ]; then
        echo -e "${GREEN}Using configuration file: configs/${config}.env${NC}"
        export $(cat "configs/${config}.env" | grep -v '^#' | xargs)
    fi
    
    # Create necessary directories
    mkdir -p notebooks data models outputs
    
    # Check NVIDIA support
    check_nvidia_support
    
        case $config in
            "llama3-8b"|"llama")
                $DOCKER_COMPOSE_CMD --profile llama up -d unsloth-llama
                ;;
            "mistral-7b"|"mistral")
                $DOCKER_COMPOSE_CMD --profile mistral up -d unsloth-mistral
                ;;
            "qwen2-7b"|"qwen")
                $DOCKER_COMPOSE_CMD --profile qwen up -d unsloth-qwen
                ;;
            *)
                $DOCKER_COMPOSE_CMD up -d unsloth-jupyter
                ;;
        esac
        
        echo -e "${GREEN}✓ Container started successfully${NC}"
    echo ""
    echo -e "${BLUE}Access Jupyter Lab at:${NC} http://localhost:${JUPYTER_HOST_PORT:-8888}"
    echo -e "${BLUE}Container name:${NC} ${CONTAINER_NAME:-unsloth-notebook}"
    echo ""
    echo "To view logs: $0 logs"
    echo "To stop: $0 stop"
}

stop_services() {
    echo -e "${YELLOW}Stopping Unsloth containers...${NC}"
    cd "$PROJECT_DIR"
    $DOCKER_COMPOSE_CMD down
    echo -e "${GREEN}✓ Containers stopped${NC}"
}

show_logs() {
    cd "$PROJECT_DIR"
    $DOCKER_COMPOSE_CMD logs -f
}

download_notebooks() {
    echo -e "${BLUE}Downloading popular Unsloth notebooks...${NC}"
    cd "$PROJECT_DIR"
    $DOCKER_COMPOSE_CMD --profile download up notebook-downloader
    echo -e "${GREEN}✓ Notebooks downloaded${NC}"
}

build_image() {
    echo -e "${BLUE}Building Unsloth Docker image...${NC}"
    cd "$PROJECT_DIR"
    $DOCKER_COMPOSE_CMD build unsloth-jupyter
    echo -e "${GREEN}✓ Image built successfully${NC}"
}

clean_up() {
    echo -e "${YELLOW}Cleaning up Docker containers and images...${NC}"
    cd "$PROJECT_DIR"
    
    # Stop and remove containers
    $DOCKER_COMPOSE_CMD down -v
    
    # Remove images
    docker images | grep unsloth | awk '{print $3}' | xargs -r docker rmi
    
    # Remove unused volumes
    docker volume prune -f
    
    echo -e "${GREEN}✓ Cleanup complete${NC}"
}

list_configs() {
    echo -e "${BLUE}Available configurations:${NC}"
    echo ""
    echo -e "${GREEN}default${NC}        - Basic Jupyter environment with Unsloth"
    
    if [ -d "$PROJECT_DIR/configs" ]; then
        for config in "$PROJECT_DIR/configs"/*.env; do
            if [ -f "$config" ]; then
                name=$(basename "$config" .env)
                echo -e "${GREEN}${name}${NC}"
                
                # Show model and description from config file
                if grep -q "MODEL_NAME" "$config"; then
                    model=$(grep "MODEL_NAME" "$config" | cut -d'=' -f2)
                    echo -e "               Model: $model"
                fi
            fi
        done
    fi
}

# Main script logic
case ${1:-help} in
    "start")
        check_requirements
        start_service "$2"
        ;;
    "stop")
        check_requirements
        stop_services
        ;;
    "logs")
        check_requirements
        show_logs
        ;;
    "download")
        check_requirements
        download_notebooks
        ;;
    "build")
        check_requirements
        build_image
        ;;
    "clean")
        check_requirements
        clean_up
        ;;
    "list")
        list_configs
        ;;
    "help"|"-h"|"--help")
        print_usage
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        echo ""
        print_usage
        exit 1
        ;;
esac