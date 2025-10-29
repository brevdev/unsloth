## 🟢 Unsloth on Brev

[![CI](https://github.com/liveaverage/unsloth-launch/actions/workflows/ci.yml/badge.svg)](https://github.com/liveaverage/unsloth-launch/actions/workflows/ci.yml)
[![Docker](https://img.shields.io/badge/docker-ready-blue.svg)](https://hub.docker.com/r/unsloth/unsloth)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Shell](https://img.shields.io/badge/shell-bash-lightgrey.svg)](https://www.gnu.org/software/bash/)

Run this command to instantly set up and launch Unsloth for local (non-swarm) Docker setups:

```bash
curl -fsSL https://raw.githubusercontent.com/liveaverage/unsloth-launch/refs/heads/main/oneshot.sh | bash
```

**What happens:**
- The Unsloth repo is cloned to `/tmp/unsloth-launch`
- The environment is configured for no Jupyter password
- The Docker container is started with GPU support (if available)
- Jupyter Lab is available at [http://localhost:8888](http://localhost:8888)

**Note:**
- This setup is for local Docker Compose only (not Swarm mode)
- GPU support is enabled via `gpus: all` in `docker-compose.yml`
- No password is set for Jupyter Lab by default

---

# Unsloth Docker Framework

A comprehensive Docker Compose framework for running [Unsloth](https://unsloth.ai/) notebooks locally with environment variable-based configuration for automatic notebook loading and model selection.

## 🚀 Quick Start

### Prerequisites

1. **Docker and Docker Compose** - [Install Docker](https://docs.docker.com/get-docker/)
   - Modern Docker installations include `docker compose` as a subcommand
   - Legacy `docker-compose` (separate binary) is also supported
2. **NVIDIA Container Toolkit** (for GPU support) - [Install Guide](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)

### Basic Usage

1. **Clone and navigate to the repo**:
   ```bash
   git clone https://github.com/your-repo/unsloth-launch.git
   cd unsloth-launch
   ```

2. **Start with default configuration** (no setup needed!):
   ```bash
   docker-compose up -d
   ```

3. **Access Jupyter Lab**: Open http://localhost:8888 in your browser

## 🏗️ Architecture

This framework provides multiple ways to run Unsloth:

### Option 1: Official Unsloth Image (Recommended)
Uses the official `unsloth/unsloth` Docker image directly with minimal customization.

### Option 2: Custom Enhanced Image
Builds on top of the official image with additional tools and automation.

## 📁 Directory Structure

```
brev-unsloth/
├── docker-compose.yml          # Main orchestration file
├── Dockerfile                  # Custom image (optional)
├── .env.template              # Environment configuration template
├── scripts/
│   ├── launcher.sh            # Main launcher script
│   ├── start-jupyter.sh       # Jupyter startup enhancement
│   └── download-notebooks.sh  # Notebook downloader
├── configs/                   # Pre-configured environments
│   ├── llama3-8b.env         # Llama 3 8B configuration
│   ├── mistral-7b.env        # Mistral 7B configuration
│   ├── qwen2-7b.env          # Qwen 2 7B configuration
│   └── codellama-7b.env      # CodeLlama 7B configuration
├── work/                      # Your main workspace
├── custom-notebooks/          # Additional custom notebooks
├── data/                      # Dataset storage
├── models/                    # Model cache
└── outputs/                   # Training outputs
```

## 🎯 Usage Examples

### Example 1: Default Environment
```bash
# Start with basic Unsloth environment
./scripts/launcher.sh start

# Access: http://localhost:8888
# Official notebooks: /workspace/unsloth-notebooks/
# Your work: /workspace/work/
```

### Example 2: Llama 3 8B Fine-tuning
```bash
# Start with Llama 3 configuration
./scripts/launcher.sh start llama3-8b

# Or manually with environment file:
docker-compose --env-file configs/llama3-8b.env up -d
```

### Example 3: Custom Model Configuration
```bash
# Set up your environment
export MODEL_NAME=unsloth/llama-3-8b-bnb-4bit
export JUPYTER_PASSWORD=mysecurepassword
export HF_TOKEN=your_huggingface_token

# Start container
./scripts/launcher.sh start
```

### Example 4: Auto-download and Start Notebook
```bash
# Set notebook URL in .env
NOTEBOOK_URL=https://raw.githubusercontent.com/unslothai/unsloth/main/examples/Llama-3-8b_Alpaca.ipynb
AUTO_START_NOTEBOOK=true

./scripts/launcher.sh start
```

## ⚙️ Configuration

All configuration is via environment variables with sensible defaults built into `docker-compose.yml`.

Override any setting by exporting before starting:
```bash
export JUPYTER_HOST_PORT=9000
export HF_TOKEN=hf_xxxxx
docker compose up -d
```

### Available Environment Variables

#### Core Settings
- `CONTAINER_NAME`: Container name (default: `unsloth-notebook`)
- `JUPYTER_PORT`: Jupyter port (default: `8888`)
- `JUPYTER_PASSWORD`: Jupyter password protection
- `SSH_HOST_PORT`: SSH access port (default: `2222`)

#### Authentication
- `HF_TOKEN`: Hugging Face token for private models
- `WANDB_API_KEY`: Weights & Biases API key
- `SSH_KEY`: SSH public key for container access
- `USER_PASSWORD`: Container user password (default: `unsloth2024`)

#### Model Configuration
- `MODEL_NAME`: Model to pre-load (e.g., `unsloth/llama-3-8b-bnb-4bit`)
- `MODEL_CACHE_DIR`: Model storage directory (default: `/workspace/models`)
- `DATASET_NAME`: Dataset to use

#### Training Parameters
- `MAX_SEQ_LENGTH`: Maximum sequence length (default: `2048`)
- `BATCH_SIZE`: Training batch size (default: `2`)
- `LEARNING_RATE`: Learning rate (default: `2e-4`)
- `NUM_TRAIN_EPOCHS`: Number of training epochs (default: `1`)

#### Resource Limits
- `MEMORY_LIMIT`: Container memory limit (default: `16G`)
- `GPU_COUNT`: Number of GPUs to use (default: `all`)

### Pre-configured Environments

#### Llama 3 8B
```bash
./scripts/launcher.sh start llama3-8b
```
- Model: `unsloth/llama-3-8b-bnb-4bit`
- Optimized for Alpaca dataset
- Sequence length: 2048

#### Mistral 7B
```bash
./scripts/launcher.sh start mistral-7b
```
- Model: `unsloth/mistral-7b-bnb-4bit`
- Optimized for instruction following

#### Qwen 2 7B
```bash
./scripts/launcher.sh start qwen2-7b
```
- Model: `unsloth/qwen2-7b-bnb-4bit`
- Multi-language support

#### CodeLlama 7B
```bash
./scripts/launcher.sh start codellama-7b
```
- Model: `unsloth/codellama-7b-bnb-4bit`
- Optimized for code generation
- Longer sequence length: 4096

## 🛠️ Advanced Features

### SSH Access
The official Unsloth image includes SSH server support:

```bash
# Generate SSH key pair
ssh-keygen -t rsa -b 4096 -f ~/.ssh/unsloth_key

# Set SSH_KEY environment variable
export SSH_KEY="$(cat ~/.ssh/unsloth_key.pub)"

# Start container
./scripts/launcher.sh start

# Connect via SSH
ssh -i ~/.ssh/unsloth_key -p 2222 unsloth@localhost
```

### Custom Docker Build
To use the enhanced image with additional tools:

1. Edit `docker-compose.yml`:
   ```yaml
   services:
     unsloth-jupyter:
       # Comment out the image line
       # image: unsloth/unsloth:latest
       
       # Uncomment the build section
       build:
         context: .
         dockerfile: Dockerfile
   ```

2. Build and start:
   ```bash
   ./scripts/launcher.sh build
   ./scripts/launcher.sh start
   ```

### Notebook Management

#### Download Popular Notebooks
```bash
./scripts/launcher.sh download
```

#### Use Custom Notebook URL
```bash
export NOTEBOOK_URL=https://example.com/my-notebook.ipynb
./scripts/launcher.sh start
```

## 📚 Container Structure

### Official Unsloth Directories
- `/workspace/unsloth-notebooks/` - Official example notebooks
- `/workspace/work/` - Your main workspace (mounted to `./work/`)
- `/home/unsloth/` - User home directory

### Additional Directories
- `/workspace/custom-notebooks/` - Custom downloaded notebooks
- `/workspace/data/` - Dataset storage
- `/workspace/models/` - Model cache
- `/workspace/outputs/` - Training outputs

## 🔧 Troubleshooting

### GPU Not Detected in PyTorch
**✅ FIXED:** This framework includes an **automatic fix** for the GPU detection issue in the official Unsloth image.

The fix:
- **Dynamically detects** your CUDA version (11.x, 12.x, etc.)
- **Automatically configures** Jupyter kernels with CUDA paths
- **No manual configuration** needed - works out of the box!

See [`GPU_CUDA_FIX.md`](GPU_CUDA_FIX.md) for technical details.

**Common GPU Issues:**
1. Verify NVIDIA drivers on host: `nvidia-smi`
2. Check Docker GPU support: `docker run --rm --gpus all nvidia/cuda:12.8-base-ubuntu20.04 nvidia-smi`
3. Verify NVIDIA Container Toolkit: `docker run --rm --gpus all nvidia/cuda:12.8-base-ubuntu20.04 nvidia-smi`
4. Test LD_LIBRARY_PATH in container: `docker exec unsloth-notebook echo $LD_LIBRARY_PATH`

### Memory Issues
Adjust memory limits in `.env`:
```bash
MEMORY_LIMIT=32G
MEMORY_RESERVATION=16G
```

### Port Conflicts
Change port mappings:
```bash
JUPYTER_HOST_PORT=8889
SSH_HOST_PORT=2223
```

### Jupyter Password Issues
Set a password for security:
```bash
JUPYTER_PASSWORD=your_secure_password
```

## 🚀 Integration Examples

### With Weights & Biases
```bash
export WANDB_API_KEY=your_wandb_key
./scripts/launcher.sh start
```

### With Private Hugging Face Models
```bash
export HF_TOKEN=your_hf_token
export MODEL_NAME=meta-llama/Llama-2-7b-hf
./scripts/launcher.sh start
```

### With Custom Dataset
```bash
# Place dataset in ./data/ directory
export DATASET_NAME=my_custom_dataset
./scripts/launcher.sh start
```

## 📖 Useful Commands

```bash
# Start container
./scripts/launcher.sh start [config]

# View logs
./scripts/launcher.sh logs

# Stop container
./scripts/launcher.sh stop

# Download notebooks
./scripts/launcher.sh download

# Clean up
./scripts/launcher.sh clean

# List configurations
./scripts/launcher.sh list

# Build custom image
./scripts/launcher.sh build

# Run tests
./scripts/test.sh
```

## 🧪 Testing

Run the test suite to verify your setup:

```bash
./scripts/test.sh
```

This checks:
- ✓ Required files present
- ✓ Shell script syntax
- ✓ Docker compose configuration
- ✓ Sudoers file permissions
- ✓ Directory structure

### Continuous Integration

This project uses GitHub Actions for CI. On every push/PR:
- ShellCheck linting
- Docker build validation
- Syntax checks

See [`.github/workflows/ci.yml`](.github/workflows/ci.yml) for details.

## 🔒 Security Notes

- Container runs as non-root `unsloth` user
- Use strong passwords for Jupyter and SSH
- SSH access requires public key authentication
- Consider firewall rules for production deployments

## 📄 License

This framework is provided as-is. The official Unsloth software has its own licensing terms.

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Make your changes
4. Test with different configurations
5. Submit a pull request

## 📞 Support

- [Unsloth Documentation](https://docs.unsloth.ai/)
- [Unsloth GitHub](https://github.com/unslothai/unsloth)
- [Docker Documentation](https://docs.docker.com/)

---

**Note**: This framework is designed to work with the official Unsloth Docker image and provides additional automation and configuration management on top of it.