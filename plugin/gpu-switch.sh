#!/bin/bash

BASE="/usr/local/emhttp/plugins/gpu-switch"
CONFIG="$BASE/config.json"
LOG="$BASE/logs/gpu.log"
STATE="$BASE/state/containers.state"
MODE="$BASE/state/mode"

log() { echo "$(date '+%F %T') | $1" >> "$LOG"; }

get_json() { jq -r "$1" "$CONFIG"; }

set_mode() { echo "$1" > "$MODE"; }

wait_gpu_idle() {
  for i in {1..30}; do
    ! nvidia-smi | grep -q " C " && return
    sleep 1
  done
}

stop_gpu() {
  for c in $(get_json '.containers.gpu[]'); do
    docker stop "$c"
  done
}

start_gpu() {
  for c in $(cat "$STATE" 2>/dev/null); do
    docker start "$c"
  done
}

save_state() {
  docker ps --format '{{.Names}}' > "$STATE"
}

enter_vm() {
  log "Entering VM mode"
  set_mode vm
  save_state
  stop_gpu
  wait_gpu_idle
}

exit_vm() {
  log "Returning to Docker mode"
  set_mode docker
  start_gpu
}

case "$1" in
  enter_vm) enter_vm ;;
  exit_vm) exit_vm ;;
esac
