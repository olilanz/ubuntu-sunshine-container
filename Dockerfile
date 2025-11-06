# Ubuntu desktop (XFCE) with headless X11 & audio pre-wired
# Extended with Sunshine for Moonlight streaming.
FROM lscr.io/linuxserver/webtop:ubuntu-xfce

LABEL org.opencontainers.image.title="Ubuntu Desktop + Sunshine" \
      org.opencontainers.image.description="Headless Ubuntu XFCE with Sunshine for Moonlight streaming" \
      org.opencontainers.image.source="https://github.com/olilanz/ubuntu-sunshine-container" \
      org.opencontainers.image.licenses="Apache-2.0"

USER root
ENV DEBIAN_FRONTEND=noninteractive

# --- Remove LSIO Webtop UI (Selkies / noVNC) binaries & configs
RUN rm -rf \
    /etc/nginx \
    /usr/sbin/nginx \
    /var/www/html \
    /usr/share/novnc \
    /opt/selkies \
    /usr/local/bin/websockify \
    /usr/local/bin/selkies-node \
    /usr/local/bin/watchdog.sh \
    /usr/bin/x11vnc \
    || true

# --- Neutralize the removed services to prevent startup errors due to missing Webtop UI
COPY ./helpers/neutralize_service.sh /tmp/neutralize_service.sh
RUN chmod +x /tmp/neutralize_service.sh
RUN for s in \
      svc-cron \
      svc-watchdog \
      svc-selkies \
      svc-nginx \
      svc-de \
    ; do \
      /tmp/neutralize_service.sh "$s"; \
    done && \
    rm /tmp/neutralize_service.sh

# --- We leave the init-* scripts in place; they will call the neutralized services harmlessly.
# --- However, there are a few hacks we need to do to keep those scripts from happy.
RUN mkdir -p /etc/nginx/sites-available && touch /etc/nginx/sites-available/default

# --- Dependencies for Sunshine runtime (X11, audio, input, DRM/GBM)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl ca-certificates \
        libopus0 libdrm2 libgbm1 libevdev2 \
        libx11-6 libxext6 libxrandr2 libxtst6 libxss1 libxfixes3 libxi6 \
        libpulse0 libudev1 x11-xserver-utils \
        xserver-xorg xserver-xorg-video-dummy dbus-x11 \
        libvulkan1 mesa-vulkan-drivers vainfo && \
    rm -rf /var/lib/apt/lists/*

# --- Dummy Xorg video driver installation
RUN apt-get update && apt-get install -y \
    xserver-xorg-video-dummy \
    xserver-xorg-core \
    xinit \
    x11-xserver-utils \
    x11-apps \
    dbus-x11 \
 && apt-get clean && rm -rf /var/lib/apt/lists/*
 
# --- Sunshine installation (fixed for Ubuntu 24.04 / LSIO base)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        software-properties-common && \
    add-apt-repository universe && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        libayatana-appindicator3-1 miniupnpc libminiupnpc17 && \
    curl -L -o /tmp/sunshine.deb \
      https://github.com/LizardByte/Sunshine/releases/download/v2025.1027.181930/sunshine-ubuntu-24.04-amd64.deb && \
    apt-get install -y /tmp/sunshine.deb || apt-get install -f -y && \
    rm -f /tmp/sunshine.deb && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# --- Basic permission fixes for dbus & GLVND
RUN mkdir -p /run/dbus /etc/glvnd/egl_vendor.d && \
    chown -R abc:abc /run/dbus /etc/glvnd/egl_vendor.d && \
    chmod 777 /run/dbus /etc/glvnd/egl_vendor.d || true

# --- Copy modified service scripts and set executable permissions
COPY root/etc /etc/
RUN find /etc/s6-overlay/s6-rc.d -type f \( -name run -o -name finish \) -exec chmod +x {} +
RUN find /etc/cont-init.d -type f -exec chmod +x {} +

# --- Copy default Sunshine configuration files
COPY root/defaults /defaults/

# --- Preparing config folders, despite them usually being mounted as volumes
RUN mkdir -p /config/.config/sunshine && \
    chown -R abc:abc /config

# --- Expose Sunshine ports
EXPOSE 47984/tcp 47989/tcp 47990/tcp 47998-48010/udp

ENV DISPLAY=:0 \
    XDG_RUNTIME_DIR=/run/user/1000 \
    XDG_SESSION_TYPE=x11
