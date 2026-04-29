# GPU Switch Manager for unRAID

![Unraid](https://img.shields.io/badge/unRAID-6.12%2B-orange)
![Version](https://img.shields.io/github/v/release/thewolfman56/gpu-switch-unraid)
![Downloads](https://img.shields.io/github/downloads/thewolfman56/gpu-switch-unraid/total)
![License](https://img.shields.io/github/license/thewolfman56/gpu-switch-unraid)
![Status](https://img.shields.io/badge/status-stable-brightgreen)

---

## 🚀 Overview

**GPU Switch Manager** is a powerful unRAID plugin that intelligently manages GPU ownership between Docker containers and a virtual machine.

It ensures smooth transitions, prevents interrupted workloads, and provides a modern UI for full control — all while respecting hardware limitations of consumer GPUs like the NVIDIA GeForce RTX 5070.

---

## ✨ Features

### 🔁 Automatic GPU Switching
- Seamlessly switch GPU between Docker and VM
- Triggered automatically when VM starts/stops

### 🎞 Tdarr-Aware Scheduling
- Integration with :contentReference[oaicite:2]{index=2}
- Prevents interrupting active transcodes
- Optional drain mode before switching

### 🧠 Multi-GPU Mapping
- Visual assignment of GPUs:
  - VM
  - Docker
  - Unused
- Perfect for multi-GPU systems

### 🎨 Advanced Web UI
- Native unRAID-style settings page
- Drag-and-drop container assignment
- Real-time GPU monitoring
- Built-in validation & warnings

### 📊 Live GPU Metrics
- Utilization graph
- Memory usage tracking
- Ownership indicator (VM vs Docker)

### 🎮 VM Control
- Start/Stop VM directly from UI
- Integrated with switching logic

### 🔐 Safe & Reliable
- Logging + error handling
- State tracking
- No unsafe system overrides

---

## 🖼 Screenshots

### Dashboard & Status
![Dashboard](assets/screenshots/dashboard.png)

### GPU Mapping Interface
![GPU Mapping](assets/screenshots/gpu-mapping.png)

### Container Assignment (Drag & Drop)
![Containers](assets/screenshots/containers.png)

### Live GPU Graph
![Graph](assets/screenshots/gpu-graph.png)

---

## 📦 Installation

### 🔹 Option 1: Community Applications (Recommended)

1. Open **Apps** tab in unRAID
2. Search for:
   GPU Switch Manager
3. Click **Install**

---

### 🔹 Option 2: Manual Install

1. Go to:
   Plugins → Install Plugin
2. Paste:
   https://raw.githubusercontent.com/thewolfman56/gpu-switch-unraid/main/plugin/gpu-switch.plg

---

## ⚙️ Setup

### 1. Configure Plugin
Go to:
  Settings → GPU Switch Manager

Set:
- VM name
- GPU/CPU containers
- Tdarr settings (optional)

---

### 2. Add QEMU Hook

Add the provided hook:
  /boot/config/plugins/gpu-switch/qemu-hook.php

Then reference it in your VM hook system.

---

### 3. Ensure Requirements

- NVIDIA GPU
- NVIDIA Driver plugin installed
- VM Manager enabled

---

## 🧠 How It Works

1. VM start detected  
2. GPU containers stopped  
3. Tdarr queue drained (optional)  
4. GPU released  
5. VM starts with GPU  

Reverse happens when VM stops.

---

## ⚠️ Limitations

Consumer GPUs like the NVIDIA GeForce RTX 5070:

- ❌ Cannot be shared between VM and Docker simultaneously  
- ✅ This plugin ensures safe, fast switching instead  

---

## 📊 Compatibility

| Component | Supported |
|----------|----------|
| unRAID | 6.12+ |
| NVIDIA GPUs | ✅ |
| AMD GPUs | ❌ (not yet) |
| Multi-GPU setups | ✅ |
| Tdarr integration | ✅ |

---

## 🛠 Troubleshooting

### GPU not switching?
- Check logs:
  /usr/local/emhttp/plugins/gpu-switch/logs/

### Tdarr not detected?
- Verify URL:
  http://Tdarr-IP-Address:8265

---

## 📜 Logging

Logs are stored at:
  /usr/local/emhttp/plugins/gpu-switch/logs/gpu.log

---

## 🤝 Contributing

Pull requests welcome!

If you’d like to add:
- AMD support
- Multi-VM support
- Advanced scheduling

Open an issue or PR.

---

## 💬 Support

- unRAID Forum Thread:
  https://forums.unraid.net/topic/YOUR-THREAD

- GitHub Issues:
  https://github.com/YOUR_USERNAME/gpu-switch-unraid/issues

---

## 🧾 License

MIT License

---

## ⭐ Acknowledgments

- unRAID community
- :contentReference[oaicite:4]{index=4} contributors
- NVIDIA ecosystem

---

## 🚀 Roadmap

- [ ] AMD GPU support  
- [ ] Multi-VM GPU routing  
- [ ] Notification system  
- [ ] Advanced scheduling rules  
- [ ] GPU heatmap UI  

---

### 👍 If you find this useful, consider starring the repo!
