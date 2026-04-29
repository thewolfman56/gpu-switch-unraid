#!/bin/bash

VERSION="1.0"

VM_NAME="Windows 11 Gaming"

GPU_CONTAINERS=(
  "Ollama"
  "tdarr_node"
  "ComfyUI"
  "Subgen"
  "Tdarr-Subtitle-OCR"
  "open-webui-nvidia"
)

CPU_CONTAINERS=(
  "Intel-IPEX-LLM-Ollama"
  "open-webui"
)

BASE_DIR="/boot/config/plugins/gpu-switch"
STATE_FILE="$BASE_DIR/state/gpu-containers.state"
LOCK_FILE="$BASE_DIR/state/vm.lock"
LOG_FILE="$BASE_DIR/logs/gpu-switch.log"
