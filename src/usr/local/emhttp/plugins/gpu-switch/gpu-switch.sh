#!/bin/bash -e -u -o pipefail
BASE="/usr/local/emhttp/plugins/gpu-switch"
CONFIG="$BASE/config.json"
LOG="$BASE/logs/gpu.log"
STATE_DIR="$BASE/state"
MODE="$BASE/state/mode"
LEGACY_GPU="__all__"
LOCK_FILE="/var/lock/gpu-switch.lock"

mkdir -p "$STATE_DIR" "$(dirname "$LOG")"

# File locking for concurrency control
exec 200>"$LOCK_FILE"
if ! flock -n 200; then
  log "ERROR: Another GPU switch operation is in progress"
  exit 1
fi

# Error handling function
handle_error() {
  local exit_code=$?
  local line_number=$1
  log "ERROR: Script failed at line $line_number with exit code $exit_code"
  cleanup
  exit $exit_code
}

trap 'handle_error $LINENO' ERR
trap 'flock -u 200' EXIT

# Cleanup function
cleanup() {
  log "Performing cleanup..."
  # Release locks, remove temp files, etc.
}

log(){ echo "$(date '+%F %T') | $1" >> "$LOG"; }

safe_id(){
  echo "$1" | tr -c 'A-Za-z0-9_.:-' '_'
}

state_file(){
  echo "$STATE_DIR/containers.$(safe_id "$1").state"
}

set_mode(){
  echo "$1" > "$MODE"
}

config_vm_name(){
  jq -r '.vm_name // empty' "$CONFIG"
}

gpu_for_vm(){
  local vm="$1"
  jq -r --arg vm "$vm" '.vm_gpu_map[$vm] // empty' "$CONFIG"
}

gpu_index(){
  local gpu="$1"
  local index
  index="$(jq -r --arg gpu "$gpu" '.gpus[$gpu].index // empty' "$CONFIG")"
  if [[ -n "$index" ]]; then
    echo "$index"
    return
  fi

  nvidia-smi --query-gpu=index,pci.bus_id --format=csv,noheader 2>/dev/null \
    | awk -F, -v gpu="$gpu" '{gsub(/^[ \t]+|[ \t]+$/, "", $1); gsub(/^[ \t]+|[ \t]+$/, "", $2); if ($2 == gpu) { print $1; exit }}'
}

gpu_query_id(){
  local gpu="$1"
  local index
  index="$(gpu_index "$gpu")"
  if [[ -n "$index" ]]; then
    echo "$index"
  else
    echo "$gpu"
  fi
}

configured_gpu_containers(){
  jq -r '.containers.gpu[]? // empty' "$CONFIG"
}

container_gpu_visible(){
  local container="$1"
  docker inspect "$container" --format '{{range .Config.Env}}{{println .}}{{end}}' 2>/dev/null \
    | awk -F= '$1=="NVIDIA_VISIBLE_DEVICES"{print $2; exit}'
}

container_uses_gpu(){
  local container="$1"
  local gpu="$2"
  local visible
  [[ "$gpu" == "$LEGACY_GPU" ]] && return 0
  visible="$(container_gpu_visible "$container")"

  [[ -z "$visible" || "$visible" == "all" ]] && return 0
  [[ "$visible" == "none" || "$visible" == "void" ]] && return 1

  IFS=',' read -ra devices <<< "$visible"
  for device in "${devices[@]}"; do
    device="${device//[[:space:]]/}"
    [[ "$device" == "$gpu" ]] && return 0
    [[ "$device" == "$(gpu_index "$gpu")" ]] && return 0
  done
  return 1
}

running_container(){
  local container="$1"
  [[ "$(docker inspect -f '{{.State.Running}}' "$container" 2>/dev/null)" == "true" ]]
}

# GPU detection with retry logic
detect_gpus_with_retry() {
  local max_retries=3
  local retry_delay=5

  for ((i=1; i<=max_retries; i++)); do
    local gpu_lines
    gpu_lines=$(nvidia-smi --query-gpu=index,name,pci.bus_id --format=csv,noheader 2>/dev/null)
    if [[ -n "$gpu_lines" ]]; then
      echo "$gpu_lines"
      return 0
    fi
    log "GPU detection failed (attempt $i/$max_retries), retrying in ${retry_delay}s..."
    sleep $retry_delay
  done

  log "ERROR: GPU detection failed after $max_retries attempts"
  return 1
}

# Container health monitoring
monitor_container_health() {
  local container="$1"
  local max_wait=60
  local elapsed=0

  while [ $elapsed -lt $max_wait ]; do
    local status
    status=$(docker inspect --format='{{.State.Status}}' "$container" 2>/dev/null)
    if [ "$status" = "running" ]; then
      return 0
    elif [ "$status" = "exited" ] || [ "$status" = "dead" ]; then
      log "ERROR: Container $container failed to start (status: $status)"
      return 1
    fi
    sleep 2
    elapsed=$((elapsed + 2))
  done

  log "ERROR: Container $container did not start within ${max_wait}s"
  return 1
}

save_state_for_gpu(){
  local gpu="$1"
  local state
  state="$(state_file "$gpu")"
  : > "$state"
  while IFS= read -r container; do
    [[ -z "$container" ]] && continue
    if running_container "$container" && container_uses_gpu "$container" "$gpu"; then
      echo "$container" >> "$state"
    fi
  done < <(configured_gpu_containers)
}

stop_gpu_containers(){
  local gpu="$1"
  while IFS= read -r container; do
    [[ -z "$container" ]] && continue
    if running_container "$container" && container_uses_gpu "$container" "$gpu"; then
      log "Stopping container $container for GPU $gpu"
      docker stop "$container"
    fi
  done < "$(state_file "$gpu")"
}

start_gpu_containers(){
  local gpu="$1"
  local state
  state="$(state_file "$gpu")"
  [[ -f "$state" ]] || return
  while IFS= read -r container; do
    [[ -z "$container" ]] && continue
    if ! running_container "$container"; then
      log "Starting container $container for GPU $gpu"
      docker start "$container"
    fi
  done < "$state"
  rm -f "$state"
}

wait_gpu_idle(){
  local gpu="$1"
  local query_id
  if [[ "$gpu" == "$LEGACY_GPU" ]]; then
    for i in {1..30}; do
      ! nvidia-smi 2>/dev/null | grep -q " C " && return 0
      sleep 1
    done
    log "Timed out waiting for all GPUs to become idle"
    return 1
  fi

  query_id="$(gpu_query_id "$gpu")"
  for i in {1..30}; do
    ! nvidia-smi -i "$query_id" 2>/dev/null | grep -q " C " && return 0
    sleep 1
  done
  log "Timed out waiting for GPU $gpu to become idle"
  return 1
}

enter_vm(){
  local vm="$1"
  local gpu
  [[ -n "$vm" ]] || vm="$(config_vm_name)"
  gpu="$(gpu_for_vm "$vm")"

  if [[ -z "$gpu" ]]; then
    log "No GPU mapping found for VM $vm; using legacy all-GPU routing"
    gpu="$LEGACY_GPU"
  fi

  log "Entering VM mode for $vm on GPU $gpu"
  set_mode "vm:$vm:$gpu"
  save_state_for_gpu "$gpu"
  stop_gpu_containers "$gpu"
  wait_gpu_idle "$gpu"
}

exit_vm(){
  local vm="$1"
  local gpu
  [[ -n "$vm" ]] || vm="$(config_vm_name)"
  gpu="$(gpu_for_vm "$vm")"

  if [[ -z "$gpu" ]]; then
    log "No GPU mapping found for VM $vm; using legacy all-GPU routing"
    gpu="$LEGACY_GPU"
  fi

  log "Returning GPU $gpu from VM $vm to Docker mode"
  set_mode docker
  start_gpu_containers "$gpu"
}

case "$1" in
 enter_vm) enter_vm "$2" ;;
 exit_vm) exit_vm "$2" ;;
esac
