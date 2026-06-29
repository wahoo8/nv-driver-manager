#!/usr/bin/env bash
# shellcheck shell=bash

ndm_require_lib cache
ndm_require_lib dkms
ndm_require_lib installer
ndm_require_lib metadata
ndm_require_lib report
ndm_require_lib system
ndm_require_lib version

ndm_cache_init
ndm_load_driver_metadata

INSTALLED_VERSION="$(ndm_get_installed_version 2>/dev/null || true)"
LATEST_VERSION="$NDM_DRIVER_VERSION"
STATUS="$(ndm_version_status "${INSTALLED_VERSION:-unknown}" "$LATEST_VERSION" 2>/dev/null || true)"
INSTALLER_PATH="$(ndm_installer_path_for_version "$LATEST_VERSION")"

printf 'NVIDIA Driver Manager %s\n\n' "$NDM_VERSION"

printf 'Driver\n'
printf '%s\n' '------'
printf 'Installed:      %s\n' "${INSTALLED_VERSION:-unknown}"
printf 'Latest:         %s\n' "$LATEST_VERSION"
printf 'Status:         %s\n' "${STATUS:-unknown}"
printf '\n'

printf 'Kernel Modules\n'
printf '%s\n' '--------------'
printf 'Type:           %s\n' "${NDM_NVIDIA_KERNEL_MODULE_TYPE:-open}"

if ndm_dkms_nvidia_registered; then
    printf 'DKMS:           Registered\n'
else
    printf 'DKMS:           Not registered\n'
fi
printf '\n'

printf 'Installed Kernels\n'
printf '%s\n' '-----------------'
while IFS= read -r kernel_version; do
    if ndm_dkms_kernel_has_nvidia "$kernel_version"; then
        printf '✓ %s\n' "$kernel_version"
    else
        printf '! %s missing NVIDIA DKMS module\n' "$kernel_version"
    fi
done < <(ndm_installed_kernels)
printf '\n'

printf 'Secure Boot\n'
printf '%s\n' '-----------'
if ndm_command_exists mokutil; then
    MOKUTIL_BIN="$(ndm_command_path mokutil)"
    "$MOKUTIL_BIN" --sb-state 2>/dev/null || true
else
    printf 'mokutil not found\n'
fi

if [[ -f "${NDM_MOK_KEY:-/var/lib/dkms/MOK.key}" &&
      -f "${NDM_MOK_CERT:-/var/lib/dkms/MOK.der}" ]]; then
    printf 'MOK signing:    Configured\n'
else
    printf 'MOK signing:    Missing\n'
fi
printf '\n'

printf 'Cache\n'
printf '%s\n' '-----'
printf 'Installer:      %s\n' "$([[ -s "$INSTALLER_PATH" ]] && printf 'Cached' || printf 'Not cached')"
printf 'Installer path: %s\n' "$INSTALLER_PATH"
printf '\n'

printf 'Last Installation\n'
printf '%s\n' '-----------------'
if [[ -r /var/log/nvidia-driver-manager/history.log ]]; then
    tail -n 1 /var/log/nvidia-driver-manager/history.log
else
    printf 'No installation history found.\n'
fi
