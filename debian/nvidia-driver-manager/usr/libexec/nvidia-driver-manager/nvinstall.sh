#!/usr/bin/env bash

set -Eeuo pipefail
IFS=$'\n\t'

CONFIG_FILE="${NDM_CONFIG_FILE:-/etc/nvidia-driver-manager.conf}"
LOG_DIR="/var/log/nvidia-driver-manager"
LOG_FILE="${LOG_DIR}/install.log"
HISTORY_FILE="${LOG_DIR}/history.log"

mkdir -p "$LOG_DIR"
: > "$LOG_FILE"

ndm_log()
{
    printf '[%(%Y-%m-%d %H:%M:%S)T] %s\n' -1 "$*" >> "$LOG_FILE"
}

ndm_history()
{
    printf '%s | %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$HISTORY_FILE"
}

ndm_fail()
{
    local message="$1"
    ndm_log "ERROR: $message"
    ndm_history "FAILED | $message"
    echo "ERROR: $message" >&2
    exit 1
}

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    ndm_fail "nvinstall.sh must run as root."
fi

ndm_log "Installation helper started."

if [[ -r "$CONFIG_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$CONFIG_FILE"
    ndm_log "Loaded configuration: $CONFIG_FILE"
else
    ndm_log "Configuration file not found, using defaults: $CONFIG_FILE"
fi

INSTALLER_PATH="${1:-}"

if [[ -z "$INSTALLER_PATH" ]]; then
    ndm_fail "No installer path supplied."
fi

if [[ ! -f "$INSTALLER_PATH" ]]; then
    ndm_fail "Installer not found: $INSTALLER_PATH"
fi

chmod 0755 "$INSTALLER_PATH"

MOK_KEY="${NDM_MOK_KEY:-/var/lib/dkms/MOK.key}"
MOK_CERT="${NDM_MOK_CERT:-/var/lib/dkms/MOK.der}"
KERNEL_MODULE_TYPE="${NDM_NVIDIA_KERNEL_MODULE_TYPE:-open}"

INSTALL_ARGS=(
    --dkms
    --allow-installation-with-running-driver
    --no-x-check
    "--kernel-module-type=$KERNEL_MODULE_TYPE"
    --rebuild-initramfs
)

if [[ -f "$MOK_KEY" && -f "$MOK_CERT" ]]; then
    INSTALL_ARGS+=(
        "--module-signing-secret-key=$MOK_KEY"
        "--module-signing-public-key=$MOK_CERT"
    )
    ndm_log "Using MOK signing files."
    ndm_log "MOK key: $MOK_KEY"
    ndm_log "MOK cert: $MOK_CERT"
else
    ndm_log "MOK signing files not found; installer may prompt or fail if Secure Boot is enabled."
fi

ndm_log "Installer: $INSTALLER_PATH"
ndm_log "Kernel module type: $KERNEL_MODULE_TYPE"
ndm_log "Installer arguments: ${INSTALL_ARGS[*]}"

ndm_log "Fixing NVIDIA DKMS pahole.sh permissions before installer."
find /var/lib/dkms/nvidia \
    -type f \
    -name 'pahole.sh' \
    -exec chmod 0755 {} \; \
    2>/dev/null || true

ndm_log "Installed kernels:"
for kernel_image in /boot/vmlinuz-*; do
    [[ -e "$kernel_image" ]] || continue
    kernel_version="$(basename "$kernel_image" | sed 's/^vmlinuz-//')"
    ndm_log "  $kernel_version"
done

if command -v mokutil >/dev/null 2>&1; then
    ndm_log "Secure Boot state: $(mokutil --sb-state 2>/dev/null || true)"
else
    ndm_log "Secure Boot state: mokutil not found"
fi

ndm_log "Launching NVIDIA installer."
bash "$INSTALLER_PATH" "${INSTALL_ARGS[@]}"
INSTALL_RESULT=$?

if (( INSTALL_RESULT != 0 )); then
    ndm_fail "NVIDIA installer exited with status $INSTALL_RESULT."
fi

ndm_log "NVIDIA installer completed successfully."

ndm_log "Fixing NVIDIA DKMS pahole.sh permissions after installer."
find /var/lib/dkms/nvidia \
    -type f \
    -name 'pahole.sh' \
    -exec chmod 0755 {} \; \
    2>/dev/null || true

ndm_log "DKMS status:"
if command -v dkms >/dev/null 2>&1; then
    dkms status 2>/dev/null | while IFS= read -r line; do
        ndm_log "  $line"
    done
elif [[ -x /usr/sbin/dkms ]]; then
    /usr/sbin/dkms status 2>/dev/null | while IFS= read -r line; do
        ndm_log "  $line"
    done
else
    ndm_log "  dkms not found"
fi

ndm_log "Updating initramfs for all kernels."
if update-initramfs -u -k all >> "$LOG_FILE" 2>&1; then
    ndm_log "initramfs update completed successfully."
else
    ndm_fail "initramfs update failed."
fi

ndm_log "Installation helper completed successfully."
ndm_history "SUCCESS | installer=$INSTALLER_PATH"

exit 0
