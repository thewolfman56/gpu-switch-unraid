#!/bin/bash
source /boot/config/plugins/gpu-switch/config.sh

log() {
  echo "$(date '+%F %T') | $1" | tee -a "$LOG_FILE"
}

get_gpu_containers() {
  docker ps --format '{{.Names}}' | while read c; do
    if docker inspect "$c" | grep -q NVIDIA_VISIBLE_DEVICES; then
      echo "$c"
    fi
  done
}

sort_by_priority() {
  for c in "$@"; do
    p=${GPU_CONTAINER_PRIORITY[$c]:-999}
    echo "$p $c"
  done | sort -n | awk '{print $2}'
}

get_gpu_process_count() {
  nvidia-smi --query-compute-apps=pid --format=csv,noheader | wc -l
}

wait_for_gpu_idle() {
  log "Waiting for GPU to become idle..."
  for i in {1..30}; do
    if ! nvidia-smi | grep -q " C "; then
      log "GPU is idle"
      return 0
    fi
    sleep 1
  done
  log "WARNING: GPU still in use after timeout"
  return 1
}

wait_for_gpu_ready() {
  log "Waiting for NVIDIA driver..."
  for i in {1..15}; do
    if nvidia-smi > /dev/null 2>&1; then
      log "GPU ready"
      return 0
    fi
    sleep 2
  done
  log "WARNING: GPU not ready"
}

save_gpu_container_state() {
  > "$STATE_FILE"
  for c in "${GPU_CONTAINERS[@]}"; do
    if docker ps --format '{{.Names}}' | grep -q "^${c}$"; then
      echo "$c" >> "$STATE_FILE"
    fi
  done
}

stop_gpu_containers() {
  log "Stopping GPU containers (priority-based)..."

  containers=$(get_gpu_containers)
  sorted=$(sort_by_priority $containers)

  for c in $sorted; do
    if docker ps --format '{{.Names}}' | grep -q "^${c}$"; then
      log "Stopping $c"
      docker stop "$c"
    fi
  done
}

start_gpu_containers() {
  if [ -f "$STATE_FILE" ]; then
    log "Restoring GPU containers..."
    while read -r c; do
      if docker ps -a --format '{{.Names}}' | grep -q "^${c}$"; then
        log "Starting $c"
        docker start "$c"
        sleep 2
      fi
    done < "$STATE_FILE"
  fi
}

start_cpu_containers() {
  for c in "${CPU_CONTAINERS[@]}"; do
    if ! docker ps --format '{{.Names}}' | grep -q "^${c}$"; then
      log "Starting CPU container: $c"
      docker start "$c"
    fi
  done
}

stop_cpu_containers() {
  for c in "${CPU_CONTAINERS[@]}"; do
    if docker ps --format '{{.Names}}' | grep -q "^${c}$"; then
      log "Stopping CPU container: $c"
      docker stop "$c"
    fi
  done
}

enter_vm_mode() {
  log "=== ENTERING VM MODE ==="

  touch "$LOCK_FILE"

  save_gpu_container_state
  stop_gpu_containers

  wait_for_gpu_idle

  start_cpu_containers

  log "VM mode ready"
}

exit_vm_mode() {
  log "=== EXITING VM MODE ==="

  rm -f "$LOCK_FILE"

  wait_for_gpu_ready

  stop_cpu_containers
  start_gpu_containers

  rm -f "$STATE_FILE"

  log "Docker mode restored"
}
