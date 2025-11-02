# Ubuntu desktop (XFCE) with headless X11 & audio pre-wired
# Extended with Sunshine for Moonlight streaming.
FROM lscr.io/linuxserver/webtop:ubuntu-xfce

LABEL org.opencontainers.image.title="Ubuntu Desktop + Sunshine" \
      org.opencontainers.image.description="Headless Ubuntu XFCE with Sunshine for Moonlight streaming" \
      org.opencontainers.image.source="https://github.com/olilanz/ubuntu-sunshine-container" \
      org.opencontainers.image.licenses="Apache-2.0"

USER root
ENV DEBIAN_FRONTEND=noninteractive

# --- Dependencies for Sunshine runtime (X11, audio, input, DRM/GBM)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates \
    libopus0 libdrm2 libgbm1 libevdev2 \
    libx11-6 libxext6 libxrandr2 libxtst6 libxss1 libxfixes3 libxi6 \
    libpulse0 libwayland-client0 libudev1 x11-xserver-utils && \
    rm -rf /var/lib/apt/lists/*

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
    apt-get install -y ./tmp/sunshine.deb || apt-get install -f -y && \
    rm -f /tmp/sunshine.deb && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# --- Ensure bash is installed (some Sunshine scripts use it explicitly)
RUN apt-get update && apt-get install -y --no-install-recommends bash

# --- Basic permission fixes for dbus & GLVND
RUN mkdir -p /run/dbus /etc/glvnd/egl_vendor.d && \
    chown -R abc:abc /run/dbus /etc/glvnd/egl_vendor.d && \
    chmod 777 /run/dbus /etc/glvnd/egl_vendor.d || true

# --- Remove Selkies / Web UI services completely
RUN rm -rf \
    /etc/nginx \
    /etc/s6-overlay/s6-rc.d/init-nginx \
    /etc/s6-overlay/s6-rc.d/init-services \
    /etc/s6-overlay/s6-rc.d/svc-de \
    /etc/s6-overlay/s6-rc.d/svc-selkies \
    /etc/s6-overlay/s6-rc.d/svc-watchdog \
    /etc/s6-overlay/s6-rc.d/init-config* \
    /etc/s6-overlay/s6-rc.d/init-video* || true && \
    rm -f /etc/s6-overlay/s6-rc.d/user/contents.d/*selkies* /etc/s6-overlay/s6-rc.d/user/contents.d/init-nginx* || true

# Remove LSIO cron service (depends on init-services; unused in headless setup)
RUN rm -rf \
    /etc/s6-overlay/s6-rc.d/svc-cron \
    /etc/s6-overlay/s6-rc.d/user/contents.d/svc-cron || true

# Remove LSIO init-crontab-config (depends on init-config; unused in Sunshine setup)
RUN rm -rf \
    /etc/s6-overlay/s6-rc.d/init-crontab-config \
    /etc/s6-overlay/s6-rc.d/user/contents.d/init-crontab-config || true

# --- Detach Xorg, PulseAudio, D-Bus from removed meta bundle
RUN rm -f \
    /etc/s6-overlay/s6-rc.d/svc-xorg/dependencies.d/init-services \
    /etc/s6-overlay/s6-rc.d/svc-pulseaudio/dependencies.d/init-services \
    /etc/s6-overlay/s6-rc.d/svc-dbus/dependencies.d/init-services || true

# Remove LSIO Docker dashboard helper (depends on init-services; unused here)
RUN rm -rf \
    /etc/s6-overlay/s6-rc.d/svc-docker \
    /etc/s6-overlay/s6-rc.d/user/contents.d/svc-docker || true

# Remove LSIO init-mods (depends on init-config-end; unused in Sunshine setup)
RUN rm -rf \
    /etc/s6-overlay/s6-rc.d/init-mods \
    /etc/s6-overlay/s6-rc.d/user/contents.d/init-mods || true

# Remove LSIO init-mods-package-install (depends on init-mods; unused)
RUN rm -rf \
    /etc/s6-overlay/s6-rc.d/init-mods-package-install \
    /etc/s6-overlay/s6-rc.d/user/contents.d/init-mods-package-install || true

# Remove LSIO init-mods-end (depends on init-mods-package-install; unused in Sunshine setup)
RUN rm -rf \
    /etc/s6-overlay/s6-rc.d/init-mods-end \
    /etc/s6-overlay/s6-rc.d/user/contents.d/init-mods-end || true

# Remove LSIO init-custom-files (depends on init-mods-end; unused after pruning)
RUN rm -rf \
    /etc/s6-overlay/s6-rc.d/init-custom-files \
    /etc/s6-overlay/s6-rc.d/user/contents.d/init-custom-files || true

# Remove LSIO nginx service (belongs to Selkies web UI stack; replaced by Sunshine)
RUN rm -rf \
    /etc/s6-overlay/s6-rc.d/svc-nginx \
    /etc/s6-overlay/s6-rc.d/user/contents.d/svc-nginx || true

# Detach xsettingsd from removed svc-nginx dependency
RUN rm -f /etc/s6-overlay/s6-rc.d/svc-xsettingsd/dependencies.d/svc-nginx || true

# Remove LSIO Selkies config initializer (depends on init-nginx; unused with Sunshine)
RUN rm -rf \
    /etc/s6-overlay/s6-rc.d/init-selkies-config \
    /etc/s6-overlay/s6-rc.d/user/contents.d/init-selkies-config || true

# Remove LSIO Selkies end marker (depends on init-video; unused after pruning)
RUN rm -rf \
    /etc/s6-overlay/s6-rc.d/init-selkies-end \
    /etc/s6-overlay/s6-rc.d/user/contents.d/init-selkies-end || true

# Detach xsettingsd from removed init-services dependency
RUN rm -f /etc/s6-overlay/s6-rc.d/svc-xsettingsd/dependencies.d/init-services || true

# --- Reset s6 user bundle to only start what we want
RUN rm -rf /etc/s6-overlay/s6-rc.d/user/contents.d/* && \
    for s in svc-xorg svc-pulseaudio svc-dbus init-sunshine; do \
      echo "$s" > /etc/s6-overlay/s6-rc.d/user/contents.d/$s ; \
    done

# --- Dummy init-video service to satisfy Sunshine dependency    
RUN mkdir -p /etc/s6-overlay/s6-rc.d/init-video && \
    echo "oneshot" > /etc/s6-overlay/s6-rc.d/init-video/type && \
    printf '#!/bin/bash\necho "init-video: dummy telemetry stub"\n' \
      > /etc/s6-overlay/s6-rc.d/init-video/run && \
    chmod +x /etc/s6-overlay/s6-rc.d/init-video/run && \
    echo "" > /etc/s6-overlay/s6-rc.d/init-video/finish && \
    chmod +x /etc/s6-overlay/s6-rc.d/init-video/finish && \
    touch /etc/s6-overlay/s6-rc.d/init-video/up && \
    echo init-video > /etc/s6-overlay/s6-rc.d/user/contents.d/init-video

# 🧩 Replace LSIO's Xorg GPU loop (calls nvidia-smi) with a dummy
RUN rm -rf /etc/s6-overlay/s6-rc.d/svc-xorg \
           /etc/s6-overlay/s6-rc.d/user/contents.d/svc-xorg && \
    mkdir -p /etc/s6-overlay/s6-rc.d/svc-xorg && \
    echo "oneshot" > /etc/s6-overlay/s6-rc.d/svc-xorg/type && \
    printf '#!/bin/bash\necho "svc-xorg: dummy placeholder for Sunshine (Xorg loop disabled)"\n' \
      > /etc/s6-overlay/s6-rc.d/svc-xorg/run && \
    chmod +x /etc/s6-overlay/s6-rc.d/svc-xorg/run && \
    echo "" > /etc/s6-overlay/s6-rc.d/svc-xorg/finish && chmod +x /etc/s6-overlay/s6-rc.d/svc-xorg/finish && \
    touch /etc/s6-overlay/s6-rc.d/svc-xorg/up && \
    echo svc-xorg > /etc/s6-overlay/s6-rc.d/user/contents.d/svc-xorg

# --- Sunshine service registration
COPY root/etc/s6-overlay/s6-rc.d/init-sunshine /etc/s6-overlay/s6-rc.d/init-sunshine
RUN echo "longrun" > /etc/s6-overlay/s6-rc.d/init-sunshine/type && \
    chmod +x /etc/s6-overlay/s6-rc.d/init-sunshine/run && \
    [ -f /etc/s6-overlay/s6-rc.d/init-sunshine/finish ] && chmod +x /etc/s6-overlay/s6-rc.d/init-sunshine/finish || true && \
    mkdir -p /etc/s6-overlay/s6-rc.d/init-sunshine/dependencies.d && \
    touch /etc/s6-overlay/s6-rc.d/init-sunshine/dependencies.d/svc-xorg && \
    touch /etc/s6-overlay/s6-rc.d/init-sunshine/dependencies.d/svc-pulseaudio

# --- Sunshine configuration directory
RUN mkdir -p /config/sunshine/logs && chown -R abc:abc /config

EXPOSE 47984/tcp 47989/tcp 47998-48010/udp
ENV DISPLAY=:0 \
    SUNSHINE_CONFIG_DIR=/config/sunshine
