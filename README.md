## License Notice

This repository and its associated Docker images and binaries are
provided **for evaluation and testing purposes only**.

🚫 Commercial use, redistribution, production deployment, or
derivative works are strictly prohibited.

If you are interested in commercial licensing, please contact:
<diwakarjravi@gmail.com>



# Celesta Demo
Dockerized implementation of Celesta, which is built upon DABA by Facebook allowing for better load balancing across GPUs

## Prerequisites

1. **NVIDIA GPU** with compute capability 6.0 or higher
2. **NVIDIA Driver** version 450.80.02 or higher
3. **Docker** version 19.03 or higher
4. **NVIDIA Container Toolkit** (nvidia-docker2)

### Installing NVIDIA Container Toolkit

```bash
# Ubuntu/Debian
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list

sudo apt-get update
sudo apt-get install -y nvidia-docker2
sudo systemctl restart docker
```

### Verify GPU Access

```bash
docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu20.04 nvidia-smi
```

## Quick Start

### 1. Load the Docker Image

Load the prebuilt docker image with the following command.

```bash
docker load -i celesta-docker.tar.gz
```

### 2. Prepare Your Dataset

Place your BAL dataset files in a directory (e.g., `./data`):

```bash
mkdir -p data
cd data
wget https://grail.cs.washington.edu/projects/bal/data/ladybug/problem-257-65132-pre.txt.bz2
bzip2 -dk problem-257-65132-pre.txt.bz2
cd ..
```

### 3. Run Celesta

```bash
./run-docker.sh --data-dir ./data \
  'mpiexec -n 1 mpi_daba_bal_dataset --dataset /data/problem-257-65132-pre.txt --iters 1000 --loss trivial --accelerated true'
```

## Available Binaries

The Docker image includes the following pre-built binaries:

- `mpi_daba_bal_dataset` - Main DABA algorithm (recommended)
- `mpi_admm_bal_dataset` - ADMM-based solver
- `mpi_dr_bal_dataset` - Douglas-Rachford solver
- `mem_comm_bal_dataset` - Memory/communication profiling version
- `ceres_bal_dataset` - Ceres baseline (optional)

## Usage Examples

### Basic Usage (Single GPU)

```bash
./run-docker.sh \
  'mpiexec -n 1 mpi_daba_bal_dataset --dataset /data/problem-257-65132-pre.txt --iters 1000 --loss trivial'
```

### Multi-GPU Usage

```bash
./run-docker.sh --num-gpus 4 \
  'mpiexec -n 4 mpi_daba_bal_dataset --dataset /data/problem-1723-156502-pre.txt --iters 1000 --loss trivial --accelerated true'
```

### Get Help for a Binary

```bash
./run-docker.sh 'mpi_daba_bal_dataset --help'
```

### Interactive Shell

```bash
docker run -it --rm --gpus all \
  -v $(pwd)/data:/data \
  celesta:latest \
  /bin/bash
```

## Distributing the Image

### Export the Docker Image

```bash
docker save celesta:latest | gzip > celesta-docker.tar.gz
```

### Transfer and Load on Another System

On the target system:

```bash
# Load the image
docker load < celesta-docker.tar.gz

# Verify it loaded
docker images | grep celesta

# Run it
docker run --rm --gpus all celesta:latest
```

## Advanced Configuration

### Custom MPI Options

```bash
./run-docker.sh \
  'mpiexec -n 2 --bind-to core --map-by socket mpi_daba_bal_dataset --dataset /data/problem.txt --iters 1000'
```

### Mount Multiple Directories

```bash
docker run --rm --gpus all \
  -v /path/to/datasets:/data \
  -v /path/to/results:/results \
  celesta:latest \
  'mpiexec -n 1 mpi_daba_bal_dataset --dataset /data/problem.txt --iters 1000 --save true'
```

### Specify GPU Devices

```bash
# Use only GPU 0 and 1
docker run --rm --gpus '"device=0,1"' \
  -v $(pwd)/data:/data \
  celesta:latest \
  'mpiexec -n 2 mpi_daba_bal_dataset --dataset /data/problem.txt --iters 1000'
```

## Troubleshooting

### "could not select device" Error

Make sure NVIDIA Container Toolkit is installed and Docker daemon has been restarted:

```bash
sudo systemctl restart docker
docker run --rm --gpus all nvidia/cuda:11.8.0-base-ubuntu20.04 nvidia-smi
```

### "No such file or directory" for Dataset

Ensure the dataset path is relative to the mounted `/data` directory inside the container:

```bash
# If your dataset is at ./my-data/problem.txt on host
./run-docker.sh --data-dir ./my-data \
  'mpiexec -n 1 mpi_daba_bal_dataset --dataset /data/problem.txt --iters 1000'
```

### MPI Warnings

MPI warnings about vader or shared memory are usually harmless in single-node configurations. These are suppressed by default via environment variables.

### Permission Denied

The container runs as a non-root user (UID 1000). Ensure your data directory has appropriate permissions:

```bash
chmod -R 755 ./data
```

## Performance Tips

1. **Use local SSD** for dataset storage to minimize I/O bottleneck
2. **Pin to cores**: Use MPI binding options for better performance
3. **Monitor GPU usage**: Run `nvidia-smi dmon` in another terminal
4. **Batch multiple runs**: Process multiple datasets in sequence to amortize container startup

## Size and System Requirements

- Docker image size: ~2.5 GB
- Runtime memory: Depends on dataset (typically 4-32 GB per GPU)
- Disk space: Ensure sufficient space for datasets and results

## Support

For issues with Celesta algorithms or parameters, reach me at:
https://linkedin.com/in/diwakar-ravichandran

For Docker-specific issues, check Docker and NVIDIA Container Toolkit documentation.
