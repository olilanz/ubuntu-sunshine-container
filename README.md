# 🧩 Headless Ubuntu + Sunshine (Xorg + PipeWire)

A **headless Ubuntu 24.04 environment** running in Docker, featuring:

- A **virtual X11 desktop** (Xorg dummy monitor)
- **PipeWire + WirePlumber** for audio
- **Sunshine** for low-latency NVENC streaming
- Full compatibility with **Moonlight** clients (iPad, iPhone, Apple TV, Mac, Windows, Linux)

This container turns your Unraid server (or any NVIDIA-equipped Linux host) into a powerful **remote desktop / gaming / development node**.  
It requires **no GPU passthrough**, **no VM**, and lets you use *both* your GPUs freely.

## 🚀 Features

- 🖥️ **Headless Xorg dummy display**
- 🎧 **PipeWire + WirePlumber**
- ☀️ **Sunshine** (NVENC encoding, low latency)
- 🎮 Works with Moonlight on all platforms
- ⚙️ **NVIDIA GPU sharing**
- 🧱 Expandable with desktops (XFCE, LXQt, etc.)

## 📁 Repository Layout

```
Dockerfile
root/
  etc/
    supervisor/
      conf.d/
        supervisord.conf
  etc/X11/xorg.conf.d/
    10-dummy.conf
README.md
```

## 🏗️ Quick Start

### Build
```bash
docker rm -f ubuntu-xfce-sunshine
docker build -t ubuntu-xfce-sunshine .
```

### Run
```bash
docker run --rm -it \
   --name ubuntu-xfce-sunshine \
   --user root \
   --gpus all \
   --runtime=nvidia \
   --shm-size=16g \
   --cap-add=SYS_NICE \
   --device /dev/uinput \
   --device /dev/nvidia-uvm \
   --device /dev/nvidia0 \
   --device /dev/nvidiactl \
   --device /dev/nvidia-modeset \
   --device /dev/dri \
   -e TZ=Europe/Copenhagen \
   -e NVIDIA_VISIBLE_DEVICES=all \
   -e NVIDIA_DRIVER_CAPABILITIES=all \
   -p 47984-47990:47984-47990/tcp \
   -p 47998-48010:47998-48010/udp \
   -v /mnt/cache/appdata/ubuntu-xfce-sunshine/config:/config \
   ubuntu-xfce-sunshine
```

### Access
```bash
docker exec -it ubuntu-xfce-sunshine bash
```

## 🌐 Sunshine Web UI

Visit:
```
http://<unraid-ip>:47990
```

## 🎮 Moonlight Setup

1. Install Moonlight
2. Add host IP
3. Pair with PIN
4. Start streaming (1080p headless desktop)

## 🔧 Volumes

| Path | Purpose |
|------|---------|
| `/config` | Sunshine settings |

## ⚙️ Environment Variables

| Variable | Purpose |
|----------|----------|
| `TZ` | Timezone |
| `DISPLAY` | Xorg display (:0) |
| `NVIDIA_VISIBLE_DEVICES` | GPU selection |
| `NVIDIA_DRIVER_CAPABILITIES` | Enable NVENC, compute, etc. |

## 🔌 Ports

| Port | Purpose |
|------|---------|
| 47984 | Web UI / pairing |
| 47998–48010 | Video/audio/input streams |

## ❤️ Credits

- Sunshine
- Moonlight
- PipeWire / WirePlumber
