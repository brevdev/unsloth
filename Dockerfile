# Use official Unsloth Docker image as base
FROM unsloth/unsloth:latest

# Switch to root for system-level installations
USER root

# Install additional system utilities if needed
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    vim \
    nano \
    htop \
    screen \
    tmux \
    && rm -rf /var/lib/apt/lists/*

# Switch back to unsloth user
USER unsloth

# Set working directory to the standard unsloth workspace
WORKDIR /workspace

# Install additional Python packages if needed
RUN pip install --user \
    wandb \
    tensorboard \
    matplotlib \
    seaborn \
    plotly \
    scikit-learn \
    gpustat \
    py-cpuinfo

# Copy scripts and configurations
COPY --chown=unsloth:unsloth scripts/ /workspace/scripts/
COPY --chown=unsloth:unsloth configs/ /workspace/configs/

# Make scripts executable
RUN chmod +x /workspace/scripts/*.sh

# Create additional workspace directories
RUN mkdir -p \
    /workspace/work \
    /workspace/custom-notebooks \
    /workspace/data \
    /workspace/models \
    /workspace/outputs

# Expose ports (Jupyter is already exposed in base image)
EXPOSE 8888 6006

# Set default environment variables compatible with unsloth image
ENV JUPYTER_ENABLE_LAB=yes
ENV JUPYTER_PORT=8888

# The official unsloth image already has a good startup command
# We'll override it only if needed via docker-compose