#!/bin/bash
MODE=$(cat /usr/local/emhttp/plugins/gpu-switch/state/mode 2>/dev/null || echo docker)
GPU=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | head -n1)
echo "{\"mode\":\"$MODE\",\"gpu\":\"$GPU\"}"
