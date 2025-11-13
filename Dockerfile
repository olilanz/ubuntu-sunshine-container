# ------------------------------------------------------------
# Sunshine headless streaming container
# Base: official Ubuntu 24.04 Sunshine image
# ------------------------------------------------------------
ARG SUNSHINE_VERSION=v2025.924.154138
ARG SUNSHINE_OS=ubuntu-24.04
FROM lizardbyte/sunshine:${SUNSHINE_VERSION}-${SUNSHINE_OS} AS sunshine-baee

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# ------------------------------------------------------------
# Install NVIDIA driver (headless, user space components only)
# ------------------------------------------------------------
USER root
RUN apt-get update && \
    apt-get install -y wget build-essential kmod && \
    wget https://us.download.nvidia.com/XFree86/Linux-x86_64/580.82.09/NVIDIA-Linux-x86_64-580.82.09.run && \
    chmod +x NVIDIA-Linux-x86_64-580.82.09.run && \
    ./NVIDIA-Linux-x86_64-580.82.09.run --no-kernel-module --silent && \
    rm NVIDIA-Linux-x86_64-580.82.09.run

# ------------------------------------------------------------
# Install display + audio stack
# ------------------------------------------------------------
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        xinit \
        xserver-xorg-core \
        x11-utils \
        x11-xserver-utils \
        mesa-utils \
        pipewire \
        pipewire-audio-client-libraries \
        pipewire-pulse pipewire-alsa alsa-utils \
        wireplumber \
        dbus-x11 \
        supervisor \
        pulseaudio-utils \
        alsa-utils \
        fonts-dejavu-core \
        nano && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------
# XFCE layer
# ------------------------------------------------------------
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        xfce4 \
        xfce4-terminal \
        mousepad \
        tango-icon-theme \
        dbus-x11 \
        xdg-utils && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# ------------------------------------------------------------
# Create runtime directories
# ------------------------------------------------------------
ENV XDG_RUNTIME_DIR=/tmp/runtime-root
RUN mkdir -p /tmp/runtime-root && chmod 700 /tmp/runtime-root

# ------------------------------------------------------------
# Copy configuration files
# ------------------------------------------------------------
COPY root/ /

# ------------------------------------------------------------
# Default environment variables
# ------------------------------------------------------------
ENV DISPLAY=:0
ENV SUNSHINE_LOG=info
ENV SUNSHINE_CONFIG_DIR=/config

# ------------------------------------------------------------
# Expose Sunshine ports
# ------------------------------------------------------------
EXPOSE 47984-47990/tcp
EXPOSE 47998-48010/udp

# ------------------------------------------------------------
# Entrypoint
# ------------------------------------------------------------
ENTRYPOINT []
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
