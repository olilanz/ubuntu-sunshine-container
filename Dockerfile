# ------------------------------------------------------------
# Sunshine headless streaming container
# Base: official Ubuntu 24.04 Sunshine image
# ------------------------------------------------------------
ARG SUNSHINE_VERSION=latest
ARG SUNSHINE_OS=ubuntu-24.04
FROM lizardbyte/sunshine:${SUNSHINE_VERSION}-${SUNSHINE_OS}

# Prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# ------------------------------------------------------------
# Install display + audio stack
# ------------------------------------------------------------
USER root
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        xserver-xorg-video-dummy \
        xinit \
        x11-xserver-utils \
        mesa-utils \
        pipewire \
        pipewire-audio-client-libraries \
        pipewire-alsa alsa-utils \
        wireplumber \
        dbus-x11 \
        supervisor \
        pulseaudio-utils \
        alsa-utils \
        fonts-dejavu-core \
        nano && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

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
# Create runtime directories
# ------------------------------------------------------------
RUN mkdir -p /tmp/runtime-gamer && chmod 700 /tmp/runtime-gamer

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
