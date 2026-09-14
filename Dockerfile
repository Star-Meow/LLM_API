FROM nvidia/cuda:12.4.1-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive

# ============================================================
# System dependencies
# ============================================================

RUN apt-get update && apt-get install -y \
    build-essential \
    git \
    cmake \
    ninja-build \
    python3 \
    python3-pip \
    python3-venv \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*


# ============================================================
# Hugging Face CLI
# ============================================================

RUN python3 -m pip install --no-cache-dir \
    --upgrade \
    "huggingface_hub"


# 確認 Python / pip / hf 都存在
RUN python3 --version \
    && python3 -m pip --version \
    && hf --version


# ============================================================
# llama.cpp
# ============================================================

WORKDIR /app

RUN git clone --depth 1 \
    https://github.com/ggml-org/llama.cpp.git


WORKDIR /app/llama.cpp


# ============================================================
# Build llama.cpp with CUDA
# ============================================================

RUN cmake -B build -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DLLAMA_BUILD_SERVER=ON \
    -DLLAMA_SERVER_BUILD_UI=OFF \
    -DGGML_CUDA=ON \
    -DGGML_NATIVE=OFF \
    -DCMAKE_EXE_LINKER_FLAGS=-Wl,--allow-shlib-undefined \
    -DCMAKE_SHARED_LINKER_FLAGS=-Wl,--allow-shlib-undefined


RUN cmake --build build \
    -j$(nproc) \
    --target llama-server llama-cli


# ============================================================
# Model directory
# ============================================================

WORKDIR /models

CMD ["bash"]