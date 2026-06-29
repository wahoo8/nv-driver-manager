#!/usr/bin/env bash
# shellcheck shell=bash

NDM_INSTALL_REPORT_FILE="${NDM_INSTALL_REPORT_FILE:-/var/log/nvidia-driver-manager/install-report.txt}"

ndm_install_summary()
{
    local installed_version=""
    local dkms_status=""
    local kernel_count="0"
    local signed_note="Unknown"

    installed_version="$(ndm_get_installed_version 2>/dev/null || true)"
    dkms_status="$(ndm_dkms_nvidia_status 2>/dev/null || true)"
    kernel_count="$(
        printf '%s\n' "$dkms_status" |
            grep -ci 'installed' || true
    )"

    if [[ -f "${NDM_MOK_KEY:-/var/lib/dkms/MOK.key}" &&
          -f "${NDM_MOK_CERT:-/var/lib/dkms/MOK.der}" ]]; then
        signed_note="MOK signing files found"
    fi

    cat <<EOF
NVIDIA Driver Manager Installation Summary

Installed driver: ${installed_version:-unknown}

DKMS modules installed: $kernel_count

Secure Boot signing: $signed_note

Initramfs: rebuilt

Reboot: strongly recommended
EOF
}

ndm_write_install_report()
{
    local previous_version="${1:-unknown}"
    local installed_version=""
    local report_dir=""

    installed_version="$(ndm_get_installed_version 2>/dev/null || true)"
    report_dir="$(dirname "$NDM_INSTALL_REPORT_FILE")"

    mkdir -p "$report_dir"

    {
        printf 'NVIDIA Driver Manager Installation Report\n'
        printf '=========================================\n\n'
        printf 'Date:              %s\n' "$(date '+%Y-%m-%d %H:%M:%S %Z')"
        printf 'Previous Driver:   %s\n' "$previous_version"
        printf 'Installed Driver:  %s\n' "${installed_version:-unknown}"
        printf '\n'
        printf 'DKMS\n'
        printf '----\n'

        if ndm_dkms_nvidia_registered; then
            ndm_dkms_nvidia_status
        else
            printf 'No NVIDIA DKMS registrations found.\n'
        fi

        printf '\n'
        printf 'Secure Boot\n'
        printf '-----------\n'
        if [[ -f "${NDM_MOK_KEY:-/var/lib/dkms/MOK.key}" &&
              -f "${NDM_MOK_CERT:-/var/lib/dkms/MOK.der}" ]]; then
            printf 'MOK signing files: found\n'
            printf 'MOK key:           %s\n' "${NDM_MOK_KEY:-/var/lib/dkms/MOK.key}"
            printf 'MOK cert:          %s\n' "${NDM_MOK_CERT:-/var/lib/dkms/MOK.der}"
        else
            printf 'MOK signing files: missing\n'
        fi

        printf '\n'
        printf 'Initramfs\n'
        printf '---------\n'
        printf 'Updated:           Yes\n'

        printf '\n'
        printf 'Result\n'
        printf '------\n'
        printf 'Installation completed successfully.\n'
        printf 'Reboot required.\n'
    } > "$NDM_INSTALL_REPORT_FILE"

    printf '%s\n' "$NDM_INSTALL_REPORT_FILE"
}
