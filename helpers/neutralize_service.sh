#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# neutralize_service.sh
# Create a dummy (oneshot) s6-overlay service for the given service name.
# Example:
#   ./neutralize_service.sh svc-watchdog
# ---------------------------------------------------------------------------

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "Usage: $0 <service-name>"
  exit 1
fi

SERVICE_NAME="$1"
BASE_DIR="/etc/s6-overlay/s6-rc.d"
SERVICE_DIR="$BASE_DIR/$SERVICE_NAME"
USER_CONTENTS="$BASE_DIR/user/contents.d"

echo "Neutralizing service: $SERVICE_NAME"

# Create service directory
mkdir -p "$SERVICE_DIR" "$USER_CONTENTS"

# Define service type
echo "oneshot" > "$SERVICE_DIR/type"

# Create run script
cat > "$SERVICE_DIR/run" <<EOF
#!/usr/bin/with-contenv bash
echo "[$(date -Iseconds)] $SERVICE_NAME: dummy stub started"
exit 0
EOF
chmod +x "$SERVICE_DIR/run"

# Create finish script
cat > "$SERVICE_DIR/finish" <<'EOF'
#!/usr/bin/with-contenv bash
# No cleanup needed; this is a dummy.
exit 0
EOF
chmod +x "$SERVICE_DIR/finish"

# Mark as 'up' (ready)
touch "$SERVICE_DIR/up"

# Register in user bundle
echo "$SERVICE_NAME" > "$USER_CONTENTS/$SERVICE_NAME"

echo "Service '$SERVICE_NAME' neutralized."
