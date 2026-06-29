#!/usr/bin/env bash

set -Eeuo pipefail
IFS=$'\n\t'

CONFIG_FILE="${NDM_CONFIG_FILE:-/etc/nvidia-driver-manager.conf}"
LOG_DIR="${NDM_LOG_DIR:-/var/log/nvidia-driver-manager}"
LOG_FILE="${LOG_DIR}/install.log"

mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "=== NVIDIA Driver Manager install helper ==="
echo "Start: $(date -Is)"
echo

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    echo "ERROR: nvinstall.sh must run as root."
    exit 1
fi

if [[ -r "$CONFIG_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$CONFIG_FILE"
fi

INSTALLER_PATH="${1:-}"

if [[ -z "$INSTALLER_PATH" ]]; then
    echo "ERROR: no installer path supplied."
    exit 1
fi

if [[ ! -f "$INSTALLER_PATH" ]]; then
    echo "ERROR: installer not found: $INSTALLER_PATH"
    exit 1
fi

chmod 0755 "$INSTALLER_PATH"

INSTALL_OPTIONS="${NDM_NVIDIA_INSTALL_OPTIONS:---silent --dkms --no-questions}"
read -r -a INSTALL_ARGS <<< "$INSTALL_OPTIONS"
MOK_KEY="${NDM_MOK_KEY:-/var/lib/dkms/MOK.key}"
MOK_CERT="${NDM_MOK_CERT:-/var/lib/dkms/MOK.der}"

if [[ -f "$MOK_KEY" && -f "$MOK_CERT" ]]; then
    INSTALL_ARGS+=(
        "--module-signing-secret-key=$MOK_KEY"
        "--module-signing-public-key=$MOK_CERT"
    )
fi
echo "Installer: $INSTALLER_PATH"
echo "Options:   ${INSTALL_ARGS[*]}"
echo

echo "Fixing NVIDIA DKMS pahole.sh permissions if present..."
find /var/lib/dkms/nvidia \
    -type f \
    -name 'pahole.sh' \
    -exec chmod 0755 {} \; \
    2>/dev/null || true

echo
echo "Installed kernels:"
for kernel_image in /boot/vmlinuz-*; do
    [[ -e "$kernel_image" ]] || continue
    kernel_version="$(basename "$kernel_image" | sed 's/^vmlinuz-//')"
    echo "  $kernel_version"
done

echo
echo "Secure Boot:"
if command -v mokutil >/dev/null 2>&1; then
    mokutil --sb-state || true
else
    echo "  mokutil not found"
fi

echo
echo "Running NVIDIA installer:"
printf '  bash "%s"' "$INSTALLER_PATH"
printf ' %q' "${INSTALL_ARGS[@]}"
printf '\n\n'

bash "$INSTALLER_PATH" "${INSTALL_ARGS[@]}"

echo
echo "Fixing NVIDIA DKMS pahole.sh permissions after installer..."
find /var/lib/dkms/nvidia \
    -type f \
    -name 'pahole.sh' \
    -exec chmod 0755 {} \; \
    2>/dev/null || true

echo
echo "DKMS status:"
if command -v dkms >/dev/null 2>&1; then
    dkms status || true
elif [[ -x /usr/sbin/dkms ]]; then
    /usr/sbin/dkms status || true
else
    echo "  dkms not found"
fi

echo
echo "Updating initramfs for all kernels..."
update-initramfs -u -k all

echo
echo "Install helper completed successfully."
echo "End: $(date -Is)"
