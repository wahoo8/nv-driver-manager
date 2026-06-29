#!/usr/bin/env bash
set -Eeuo pipefail
IFS=$'\n\t'

STATE_DIR="/var/lib/nvidia-driver-manager"
PENDING_FILE="$STATE_DIR/pending-installer"
LOG_DIR="/var/log/nvidia-driver-manager"
LOG_FILE="$LOG_DIR/offline-install.log"

mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "=== NVIDIA Driver Manager offline install ==="
echo "Start: $(date -Is)"

if [[ ! -r "$PENDING_FILE" ]]; then
    echo "ERROR: pending installer file not found: $PENDING_FILE"
    exit 1
fi

INSTALLER_PATH="$(cat "$PENDING_FILE")"

if [[ ! -f "$INSTALLER_PATH" ]]; then
    echo "ERROR: installer not found: $INSTALLER_PATH"
    exit 1
fi

/usr/libexec/nvidia-driver-manager/nvinstall.sh "$INSTALLER_PATH"

rm -f "$PENDING_FILE"

echo "Offline install completed."
echo "End: $(date -Is)"
