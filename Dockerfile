# Ubuntu desktop (XFCE) with headless X11 & audio pre-wired
# We extend it with Sunshine so you can stream to Moonlight clients.
FROM lscr.io/linuxserver/webtop:ubuntu-xfce

LABEL org.opencontainers.image.title="Ubuntu Desktop + Sunshine" \
      org.opencontainers.image.description="Headless Ubuntu XFCE with Sunshine for Moonlight streaming" \
      org.opencontainers.image.source="https://github.com/olilanz/ubuntu-sunshine-container" \
      org.opencontainers.image.licenses="Apache-2.0"

USER root
ENV DEBIAN_FRONTEND=noninteractive

# Sunshine runtime deps (X11, audio, GBM/DRM, input/event libs)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates \
    libopus0 libdrm2 libgbm1 libevdev2 \
    libx11-6 libxext6 libxrandr2 libxtst6 libxss1 libxfixes3 libxi6 \
    libpulse0 libwayland-client0 libudev1 x11-xserver-utils

# Remove all nginx / noVNC traces from LSIO Webtop base (that's the interface we are replacing with Sunshine)
RUN find /etc/s6-overlay -depth \( -path "*/init-nginx*" -o -path "*/svc-nginx*" \) -exec rm -rf {} + \
 && find /etc/s6-overlay -type f -path "*/contents.d/nginx" -delete \
 && find /etc/s6-overlay -type f -path "*/contents.d/init-nginx" -delete \
 && find /etc/s6-overlay -type f -path "*/contents.d/svc-nginx" -delete \
 && rm -rf /etc/nginx || true

# --- Fix dbus and video permissions instead of deleting them ---
RUN mkdir -p /run/dbus /etc/glvnd/egl_vendor.d \
 && chown -R abc:abc /run/dbus /etc/glvnd/egl_vendor.d \
 && chmod 777 /run/dbus /etc/glvnd/egl_vendor.d \
 && sed -i 's/s6-setuidgid abc //g' /etc/s6-overlay/s6-rc.d/init-video/run

# ------------------------------------------------------------------------------
# 🧹 Prune LSIO Webtop/Selkies root bundles to disable the browser-based UI
# Removing these breaks the dependency chain, causing s6 to ignore the rest.
# ------------------------------------------------------------------------------
RUN rm -rf \
  /etc/s6-overlay/s6-rc.d/init-nginx \
  /etc/s6-overlay/s6-rc.d/init-config \
  /etc/s6-overlay/s6-rc.d/init-video \
  /etc/s6-overlay/s6-rc.d/user/contents.d/init-nginx \
  /etc/s6-overlay/s6-rc.d/user/contents.d/init-config \
  /etc/s6-overlay/s6-rc.d/user/contents.d/init-video || true

  # Remove dangling Selkies service referencing init-config
RUN rm -rf \
  /etc/s6-overlay/s6-rc.d/init-config-end \
  /etc/s6-overlay/s6-rc.d/user/contents.d/init-config-end || true

# ------------------------------------------------------------------------------
# 🚀 Remove the LSIO Webtop meta-bundle that wires Selkies services together
# This cuts off all remaining dependency chains (config, nginx, mods, etc.)
# ------------------------------------------------------------------------------
RUN rm -rf \
  /etc/s6-overlay/s6-rc.d/init-services \
  /etc/s6-overlay/s6-rc.d/user/contents.d/init-services \
  /etc/s6-overlay/s6-rc.d/init-config-end \
  /etc/s6-overlay/s6-rc.d/user/contents.d/init-config-end || true

# ------------------------------------------------------------------------------
# 🧹 Remove LSIO cron service (depends on init-services, unused in headless mode)
# ------------------------------------------------------------------------------
RUN rm -rf \
  /etc/s6-overlay/s6-rc.d/svc-cron \
  /etc/s6-overlay/s6-rc.d/user/contents.d/svc-cron || true

# ------------------------------------------------------------------------------
# 🧹 Remove LSIO dbus wrapper service (depends on init-services, redundant in XFCE)
# ------------------------------------------------------------------------------
RUN rm -rf \
  /etc/s6-overlay/s6-rc.d/svc-dbus \
  /etc/s6-overlay/s6-rc.d/user/contents.d/svc-dbus || true

# ------------------------------------------------------------------------------
# 🧩 Patch LSIO svc-de dependency to remove the obsolete init-services link
# Keeps XFCE startup but avoids undefined dependency failures
# ------------------------------------------------------------------------------
RUN rm -f /etc/s6-overlay/s6-rc.d/svc-de/dependencies.d/init-services || true

# ------------------------------------------------------------------------------
# 🧹 Remove LSIO Docker dashboard helper (depends on init-services, unused here)
# ------------------------------------------------------------------------------
RUN rm -rf \
  /etc/s6-overlay/s6-rc.d/svc-docker \
  /etc/s6-overlay/s6-rc.d/user/contents.d/svc-docker || true

# ------------------------------------------------------------------------------
# 🎧 Keep PulseAudio but detach it from removed init-services bundle
# ------------------------------------------------------------------------------
RUN rm -f /etc/s6-overlay/s6-rc.d/svc-pulseaudio/dependencies.d/init-services || true

# ------------------------------------------------------------------------------
# 🧹 Remove Selkies (browser-based desktop layer, replaced by Sunshine)
# ------------------------------------------------------------------------------
RUN rm -rf \
  /etc/s6-overlay/s6-rc.d/svc-selkies \
  /etc/s6-overlay/s6-rc.d/user/contents.d/svc-selkies || true

# ------------------------------------------------------------------------------
# 🧹 Remove Selkies watchdog (depends on init-services; unused after pruning)
# ------------------------------------------------------------------------------
RUN rm -rf \
  /etc/s6-overlay/s6-rc.d/svc-watchdog \
  /etc/s6-overlay/s6-rc.d/user/contents.d/svc-watchdog || true

# ------------------------------------------------------------------------------
# 🪚 Detach XFCE desktop from Selkies dependency (we use Sunshine instead)
# ------------------------------------------------------------------------------
RUN rm -f /etc/s6-overlay/s6-rc.d/svc-de/dependencies.d/svc-selkies || true

# ------------------------------------------------------------------------------
# 🧹 Remove LSIO Selkies Xorg service (replaced by Sunshine/XFCE headless display)
# ------------------------------------------------------------------------------
RUN rm -rf \
  /etc/s6-overlay/s6-rc.d/svc-xorg \
  /etc/s6-overlay/s6-rc.d/user/contents.d/svc-xorg || true

# ------------------------------------------------------------------------------
# 🧹 Remove LSIO umbrella desktop environment bundle (replaced by Sunshine)
# ------------------------------------------------------------------------------
RUN rm -rf \
  /etc/s6-overlay/s6-rc.d/svc-de \
  /etc/s6-overlay/s6-rc.d/user/contents.d/svc-de || true

# --------------------------------------------------------------------------
# 🩹 Patch Sunshine s6 service to remove obsolete dependency on svc-de
# --------------------------------------------------------------------------
RUN if [ -f /etc/s6-overlay/s6-rc.d/init-sunshine/dependencies ]; then \
      sed -i '/svc-de/d' /etc/s6-overlay/s6-rc.d/init-sunshine/dependencies; \
    fi

RUN find /etc/s6-overlay/s6-rc.d -type f -name dependencies -exec sed -i '/svc-de/d' {} \; && \
    find /etc/s6-overlay/s6-rc.d -type f -name upstream -exec sed -i '/svc-de/d' {} \;


# ---- Sunshine install ----
# Pin a version to keep builds reproducible. You can override at build time:
#   docker build --build-arg SUNSHINE_VERSION=0.24.0 .
RUN curl -L -o /tmp/sunshine.deb \
  https://github.com/LizardByte/Sunshine/releases/download/v2025.1027.181930/sunshine-ubuntu-24.04-amd64.deb \
  && apt-get install -y /tmp/sunshine.deb \
  && rm -f /tmp/sunshine.deb \
  && rm -rf /var/lib/apt/lists/*

# Patch Sunshine's s6 service to depend on X11 and PulseAudio being ready
RUN mkdir -p /etc/s6-overlay/s6-rc.d/init-sunshine/dependencies.d && \
    touch /etc/s6-overlay/s6-rc.d/init-sunshine/dependencies.d/svc-de && \
    touch /etc/s6-overlay/s6-rc.d/init-sunshine/dependencies.d/svc-pulseaudio


# Create a place for Sunshine config and make sure the lsio 'abc' user owns it
RUN mkdir -p /config/sunshine/logs && chown -R abc:abc /config

# Copy s6 service to launch Sunshine after X & audio are ready
# (LinuxServer.io images use s6-overlay; dropping a service here auto-enables it)
# Disable init-nginx service to avoid permission issues
#RUN rm -rf /etc/s6-overlay/s6-rc.d/init-nginx
COPY root/ /

# Register Sunshine with s6
RUN chmod +x /etc/s6-overlay/s6-rc.d/init-sunshine/run \
    && chmod +x /etc/s6-overlay/s6-rc.d/init-sunshine/finish \
    && echo "longrun" > /etc/s6-overlay/s6-rc.d/init-sunshine/type \
    && echo init-sunshine > /etc/s6-overlay/s6-rc.d/user/contents.d/init-sunshine

# ------------------------------------------------------------------------------
# 🩹 Ensure Sunshine service is valid and visible to s6
# ------------------------------------------------------------------------------
RUN echo init-sunshine > /etc/s6-overlay/s6-rc.d/user/contents.d/init-sunshine


# --------------------------------------------------------------------------
# 🧹 Force-remove any residual 'svc-de' registrations from user stage
# --------------------------------------------------------------------------
RUN rm -f /etc/s6-overlay/s6-rc.d/user/contents.d/svc-de \
          /etc/s6-overlay/s6-rc.d/user/contents.d/init-sunshine || true

# --------------------------------------------------------------------------
# 🩹 Re-register Sunshine service as standalone (no upstream dependencies)
# --------------------------------------------------------------------------
RUN echo init-sunshine > /etc/s6-overlay/s6-rc.d/user/contents.d/init-sunshine && \
    echo "" > /etc/s6-overlay/s6-rc.d/init-sunshine/dependencies && \
    echo "" > /etc/s6-overlay/s6-rc.d/init-sunshine/upstream


# --------------------------------------------------------------------------
# 🧩 Create a dummy svc-de service to satisfy legacy dependency references
# --------------------------------------------------------------------------
RUN mkdir -p /etc/s6-overlay/s6-rc.d/svc-de && \
    echo "oneshot" > /etc/s6-overlay/s6-rc.d/svc-de/type && \
    printf '#!/usr/bin/execlineb -P\ns6-echo "svc-de: dummy placeholder for pruned LSIO desktop"\n' \
      > /etc/s6-overlay/s6-rc.d/svc-de/run && \
    chmod +x /etc/s6-overlay/s6-rc.d/svc-de/run && \
    echo "" > /etc/s6-overlay/s6-rc.d/svc-de/finish && chmod +x /etc/s6-overlay/s6-rc.d/svc-de/finish && \
    touch /etc/s6-overlay/s6-rc.d/svc-de/up && \
    echo svc-de > /etc/s6-overlay/s6-rc.d/user/contents.d/svc-de

# --------------------------------------------------------------------------
# 🧩 Create dummy init-services service to satisfy dangling dependencies
# --------------------------------------------------------------------------
RUN mkdir -p /etc/s6-overlay/s6-rc.d/init-services && \
    echo "oneshot" > /etc/s6-overlay/s6-rc.d/init-services/type && \
    printf '#!/usr/bin/execlineb -P\ns6-echo "init-services: dummy placeholder for pruned LSIO stack"\n' \
      > /etc/s6-overlay/s6-rc.d/init-services/run && \
    chmod +x /etc/s6-overlay/s6-rc.d/init-services/run && \
    echo "" > /etc/s6-overlay/s6-rc.d/init-services/finish && chmod +x /etc/s6-overlay/s6-rc.d/init-services/finish && \
    touch /etc/s6-overlay/s6-rc.d/init-services/up && \
    echo init-services > /etc/s6-overlay/s6-rc.d/user/contents.d/init-services

# --------------------------------------------------------------------------
# 🧩 Create dummy svc-xorg service to satisfy dependencies of GUI helpers
# --------------------------------------------------------------------------
RUN mkdir -p /etc/s6-overlay/s6-rc.d/svc-xorg && \
    echo "oneshot" > /etc/s6-overlay/s6-rc.d/svc-xorg/type && \
    printf '#!/usr/bin/execlineb -P\ns6-echo "svc-xorg: dummy placeholder for pruned LSIO Xorg wrapper"\n' \
      > /etc/s6-overlay/s6-rc.d/svc-xorg/run && \
    chmod +x /etc/s6-overlay/s6-rc.d/svc-xorg/run && \
    echo "" > /etc/s6-overlay/s6-rc.d/svc-xorg/finish && chmod +x /etc/s6-overlay/s6-rc.d/svc-xorg/finish && \
    touch /etc/s6-overlay/s6-rc.d/svc-xorg/up && \
    echo svc-xorg > /etc/s6-overlay/s6-rc.d/user/contents.d/svc-xorg

# --------------------------------------------------------------------------
# 🧩 Create dummy init-config service to satisfy legacy Webtop dependencies
# --------------------------------------------------------------------------
RUN mkdir -p /etc/s6-overlay/s6-rc.d/init-config && \
    echo "oneshot" > /etc/s6-overlay/s6-rc.d/init-config/type && \
    printf '#!/usr/bin/execlineb -P\ns6-echo "init-config: dummy placeholder for pruned LSIO config stage"\n' \
      > /etc/s6-overlay/s6-rc.d/init-config/run && \
    chmod +x /etc/s6-overlay/s6-rc.d/init-config/run && \
    echo "" > /etc/s6-overlay/s6-rc.d/init-config/finish && chmod +x /etc/s6-overlay/s6-rc.d/init-config/finish && \
    touch /etc/s6-overlay/s6-rc.d/init-config/up && \
    echo init-config > /etc/s6-overlay/s6-rc.d/user/contents.d/init-config

# --------------------------------------------------------------------------
# 🧩 Create dummy init-config-end service to satisfy remaining dependencies
# --------------------------------------------------------------------------
RUN mkdir -p /etc/s6-overlay/s6-rc.d/init-config-end && \
    echo "oneshot" > /etc/s6-overlay/s6-rc.d/init-config-end/type && \
    printf '#!/usr/bin/execlineb -P\ns6-echo "init-config-end: dummy placeholder for pruned LSIO config stage end"\n' \
      > /etc/s6-overlay/s6-rc.d/init-config-end/run && \
    chmod +x /etc/s6-overlay/s6-rc.d/init-config-end/run && \
    echo "" > /etc/s6-overlay/s6-rc.d/init-config-end/finish && chmod +x /etc/s6-overlay/s6-rc.d/init-config-end/finish && \
    touch /etc/s6-overlay/s6-rc.d/init-config-end/up && \
    echo init-config-end > /etc/s6-overlay/s6-rc.d/user/contents.d/init-config-end

# --------------------------------------------------------------------------
# 🧩 Create dummy init-video service to satisfy init-selkies-end dependency
# --------------------------------------------------------------------------
RUN mkdir -p /etc/s6-overlay/s6-rc.d/init-video && \
    echo "oneshot" > /etc/s6-overlay/s6-rc.d/init-video/type && \
    printf '#!/usr/bin/execlineb -P\ns6-echo "init-video: dummy placeholder for pruned LSIO GPU setup stage"\n' \
      > /etc/s6-overlay/s6-rc.d/init-video/run && \
    chmod +x /etc/s6-overlay/s6-rc.d/init-video/run && \
    echo "" > /etc/s6-overlay/s6-rc.d/init-video/finish && chmod +x /etc/s6-overlay/s6-rc.d/init-video/finish && \
    touch /etc/s6-overlay/s6-rc.d/init-video/up && \
    echo init-video > /etc/s6-overlay/s6-rc.d/user/contents.d/init-video


# Network notes:
# - 47984/tcp: Sunshine web UI & pairing
# - 47989/tcp: control
# - 47998-48010/udp: video/audio/game data (range commonly used)
EXPOSE 47984/tcp 47989/tcp 47998-48010/udp

# Helpful defaults; lscr.io/webtop uses DISPLAY=:0 already.
ENV DISPLAY=:0 \
    SUNSHINE_CONFIG_DIR=/config/sunshine

# Back to the non-root 'abc' user for runtime safety
USER abc
