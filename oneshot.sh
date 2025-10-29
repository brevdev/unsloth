#!/bin/bash
set -e

REPO_URL="https://github.com/liveaverage/unsloth-launch.git"
REPO_DIR="/tmp/unsloth-launch"

# 1. Remove and reclone repo in /tmp
if [ -d "$REPO_DIR" ]; then
    echo "Removing existing $REPO_DIR ..."
    rm -rf "$REPO_DIR"
fi
echo "Cloning $REPO_URL into $REPO_DIR ..."
git clone "$REPO_URL" "$REPO_DIR"
cd "$REPO_DIR"

# 2. Configure for passwordless Jupyter (via environment variable)
echo "Configuring for passwordless Jupyter..."
export JUPYTER_PASSWORD=""

# 3. Detect docker compose command
if docker compose version &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker compose"
elif command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker-compose"
else
    echo "Docker Compose not found. Please install Docker Compose."
    exit 1
fi

# 4. Start the container
$DOCKER_COMPOSE_CMD up -d unsloth-jupyter

# 5. Show status and access info
echo -e "\nUnsloth Launch is running!"
echo "Access Jupyter Lab at: http://localhost:8888 (no password)"
$DOCKER_COMPOSE_CMD ps
