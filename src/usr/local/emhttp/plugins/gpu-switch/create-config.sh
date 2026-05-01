#!/bin/bash
CONFIG_FILE="/usr/local/emhttp/plugins/gpu-switch/config.json"

if [ ! -f "$CONFIG_FILE" ]; then
  cat > "$CONFIG_FILE" << 'EOF'
{
  "vm_name": "",
  "auto_switch": true,
  "tdarr": {
    "enabled": true,
    "url": "http://localhost:8265"
  },
  "containers": {
    "gpu": [],
    "cpu": []
  },
  "vm_gpu_map": {},
  "gpus": {}
}
EOF
fi