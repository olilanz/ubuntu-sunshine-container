# Ubuntu desktop (XFCE) with headless X11 & audio pre-wired
# We extend it with Sunshine so you can stream to Moonlight clients.
FROM lscr.io/linuxserver/webtop:ubuntu-xfce

# ---- base setup ----
USER root
ENV DEBIAN_FRONTEND=noninteractive

# Sunshine runtime deps (X11, audio, GBM/DRM, input/event libs)
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates \
    libopus0 libdrm2 libgbm1 libevdev2 \
    libx11-6 libxext6 libxrandr2 libxtst6 libxss1 libxfixes3 libxi6 \
    libpulse0 libwayland-client0 libudev1 x11-xserver-utils \
  && rm -rf /var/lib/apt/lists/*

# ---- Sunshine install ----
# Pin a version to keep builds reproducible. You can override at build time:
#   docker build --build-arg SUNSHINE_VERSION=0.24.0 .
ARG SUNSHINE_VERSION=0.24.0
ARG ARCH=amd64
RUN curl -L -o /tmp/sunshine.deb \
      https://github.com/LizardByte/Sunshine/releases/download/v${SUNSHINE_VERSION}/sunshine_${SUNSHINE_VERSION}_${ARCH}.deb \
  && apt-get update \
  && apt-get install -y /tmp/sunshine.deb || (apt-get -f install -y && apt-get install -y /tmp/sunshine.deb) \
  && rm -f /tmp/sunshine.deb

# Create a place for Sunshine config and make sure the lsio 'abc' user owns it
RUN mkdir -p /config/sunshine && chown -R abc:abc /config

# Copy s6 service to launch Sunshine after X & audio are ready
# (LinuxServer.io images use s6-overlay; dropping a service here auto-enables it)
COPY root/ /

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
