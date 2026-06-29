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

echo "Stopping display manager..."
systemctl stop gdm.service 2>/dev/null || true
systemctl stop display-manager.service 2>/dev/null || true
sleep 3

echo "Stopping NVIDIA persistence daemon..."
systemctl stop nvidia-persistenced.service 2>/dev/null || true

echo "Unloading NVIDIA kernel modules..."
modprobe -r nvidia_drm 2>/dev/null || true
modprobe -r nvidia_modeset 2>/dev/null || true
modprobe -r nvidia_uvm 2>/dev/null || true
modprobe -r nvidia 2>/dev/null || true

if lsmod | awk '{print $1}' | grep -qE '^nvidia(_drm|_modeset|_uvm)?$'; then
    echo "ERROR: NVIDIA modules are still loaded:"
    lsmod | grep '^nvidia' || true
    echo
    echo "A process is still using the NVIDIA driver. Installation cannot continue safely."
    exit 1
fi

/usr/libexec/nvidia-driver-manager/nvinstall.sh "$INSTALLER_PATH"

rm -f "$PENDING_FILE"

echo "Offline install completed."
echo "End: $(date -Is)"
