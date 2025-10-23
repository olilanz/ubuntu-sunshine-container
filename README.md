# 🧩 Ubuntu Desktop + Sunshine

**Ubuntu Desktop (XFCE) running headless in Docker, with [Sunshine](https://github.com/LizardByte/Sunshine) for low-latency streaming to [Moonlight](https://moonlight-stream.org/) clients.**

This image turns your Unraid server (or any NVIDIA-equipped Linux host) into a full remote workstation:
- Use it as a **personal Ubuntu desktop** (browser, VS Code, terminals, dev tools)
- Stream it to an **iPad, Apple TV, Mac, or PC** using Moonlight
- Play **native Linux games or emulators**
- Encode using **NVENC** on your NVIDIA GPU for ultra-smooth 1080p60 (or higher) streaming

## 🚀 Quick Start (Unraid)

1. **Install the NVIDIA Driver plugin** on Unraid  
   – Required for NVENC / CUDA in containers.

2. **Search “Ubuntu Desktop – Sunshine”** in the Community Applications tab  
   or add your template repo manually.

3. **Apply these basic settings:**
   - Appdata path: `/mnt/user/appdata/ubuntu-desktop-sunshine`
   - Workspace path: `/mnt/user/workspace`
   - GPU runtime: `--runtime=nvidia`
   - Ports: 47984/tcp, 47989/tcp, 47998–48010/udp
   - Resolution: 1920×1080 @ 60 Hz (default)

4. **Launch the container**  
   Sunshine starts automatically once the desktop and audio stack are ready.

5. **Pair your Moonlight client**  
   - Open Moonlight on iPad, Apple TV, Mac, or PC.  
   - Add your server by IP (port 47984).  
   - Approve the pairing request in Sunshine’s web UI.

## 🎮 Features

- 🖥️ Full **Ubuntu 24.04 LTS** desktop (XFCE 4)
- 🎧 **PulseAudio** sound (bi-directional mic support)
- ⚙️ **Sunshine** streaming server (NVENC HEVC/H.264)
- 🧠 **CUDA-ready** for light GPU compute or LLM workloads
- 🧑‍💻 Ideal for **remote development** (VS Code, Git, browsers, Docker CLI)
- 📦 All persistent config stored under `/config`
- 🔒 No ports exposed externally by default – LAN or VPN only

## 🧰 Volumes

| Path | Purpose |
|------|----------|
| `/config` | User config, Sunshine settings, XFCE profile |
| `/workspace` | Your dev projects, repos, or shared data |

## 🔧 Environment Variables

| Variable | Default | Description |
|-----------|----------|-------------|
| `PUID` | `1000` | Container user ID |
| `PGID` | `1000` | Container group ID |
| `TZ` | `Europe/Copenhagen` | Time zone |
| `NVIDIA_VISIBLE_DEVICES` | `all` | Select GPU(s) |
| `NVIDIA_DRIVER_CAPABILITIES` | `all` | Enable compute/video/utility |
| `CUSTOM_RES_W` | `1920` | Virtual monitor width |
| `CUSTOM_RES_H` | `1080` | Virtual monitor height |
| `CUSTOM_REFRESH_RATE` | `60` | Virtual monitor refresh rate |

## 🛰️ Ports

| Port | Protocol | Purpose |
|------|-----------|----------|
| 47984 | TCP | Sunshine Web UI & pairing |
| 47989 | TCP | Control channel |
| 47998–48010 | UDP | Video + audio + input streams |
| 3000 | TCP (optional) | noVNC Web desktop (admin only) |

## 🧩 Tips

- Use **HEVC (H.265)** for the best quality/bitrate ratio; your iPad Pro decodes it natively.
- For 1080p60 streaming, start at **25–35 Mbps** bitrate.
- Disable XFCE’s compositor if you notice any input lag.
- Keep ports closed to the public internet; use your LAN or a VPN for remote access.
- Updates: rebuild or pull when a new Sunshine release is published.

## 🧱 Folder Layout (repo)

```
ubuntu-desktop-sunshine/
├── Dockerfile
├── README.md
├── icon.png
└── root/
    └── etc/
        └── services.d/
            └── sunshine/
                ├── run
                └── finish
```

## ❤️ Credits

- [LinuxServer.io Webtop](https://github.com/linuxserver/docker-webtop)
- [LizardByte Sunshine](https://github.com/LizardByte/Sunshine)
- [Moonlight](https://moonlight-stream.org/)

## 🪄 Example Use Cases

| Scenario | How |
|-----------|-----|
| **Play Minecraft (Java)** | Install natively in Ubuntu, add to Sunshine apps |
| **Develop remotely** | Run VS Code in the desktop or connect via Remote-SSH |
| **Family couch gaming** | Connect iPad → TV HDMI → Moonlight session |
| **Light GPU compute** | Use CUDA or run LLM containers alongside |

### 🧭 License
MIT / Apache 2.0
