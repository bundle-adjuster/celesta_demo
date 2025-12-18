#!/bin/bash
# Run Celesta Docker container with proper GPU and MPI configuration

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Default values
IMAGE_NAME="${IMAGE_NAME:-celesta}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
DATA_DIR="${DATA_DIR:-$(pwd)/data}"
NUM_GPUS="${NUM_GPUS:-1}"

# Usage information
usage() {
    echo "Usage: $0 [OPTIONS] [COMMAND]"
    echo ""
    echo "Options:"
    echo "  --data-dir DIR      Directory containing datasets (default: ./data)"
    echo "  --num-gpus N        Number of GPUs to use (default: 1)"
    echo "  --image NAME:TAG    Docker image to use (default: celesta:latest)"
    echo "  --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  # Show available binaries"
    echo "  $0"
    echo ""
    echo "  # Run with custom dataset directory"
    echo "  $0 --data-dir /path/to/datasets 'mpiexec -n 1 mpi_daba_bal_dataset --dataset /data/problem.txt --iters 1000'"
    echo ""
    echo "  # Use 2 GPUs"
    echo "  $0 --num-gpus 2 'mpiexec -n 2 mpi_daba_bal_dataset --dataset /data/problem.txt --iters 1000'"
    echo ""
    echo "  # Get help for a specific binary"
    echo "  $0 'mpi_daba_bal_dataset --help'"
    exit 0
}

# Parse arguments
COMMAND=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --data-dir)
            DATA_DIR="$2"
            shift 2
            ;;
        --num-gpus)
            NUM_GPUS="$2"
            shift 2
            ;;
        --image)
            IFS=':' read -r IMAGE_NAME IMAGE_TAG <<< "$2"
            shift 2
            ;;
        --help)
            usage
            ;;
        *)
            COMMAND="$1"
            shift
            ;;
    esac
done

# Create data directory if it doesn't exist
mkdir -p "$DATA_DIR"

echo -e "${GREEN}=== Running Celesta Docker Container ===${NC}"
echo "Image: ${IMAGE_NAME}:${IMAGE_TAG}"
echo "Data directory: $DATA_DIR"
echo "GPUs: $NUM_GPUS"
echo ""

# Check if nvidia-docker runtime is available
if ! docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu20.04 nvidia-smi &>/dev/null; then
    echo -e "${YELLOW}Warning: GPU access might not be available.${NC}"
    echo "Make sure you have nvidia-docker2 installed."
    echo "See: https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html"
    echo ""
fi

# Run the container
if [ -z "$COMMAND" ]; then
    # No command provided, show default message
    docker run --rm \
        --gpus all \
        -v "$DATA_DIR:/data" \
        "${IMAGE_NAME}:${IMAGE_TAG}"
else
    # Run the provided command
    docker run --rm \
        --gpus all \
        -v "$DATA_DIR:/data" \
        "${IMAGE_NAME}:${IMAGE_TAG}" \
        "$COMMAND"
fi
