#!/bin/bash
source /boot/config/plugins/gpu-switch/config.sh

if [ -f "$LOCK_FILE" ]; then
  echo "Switching to Docker mode..."
  /boot/config/plugins/gpu-switch/gpu-switch.sh exit_vm_mode
else
  echo "Switching to VM mode..."
  /boot/config/plugins/gpu-switch/gpu-switch.sh enter_vm_mode
fi
