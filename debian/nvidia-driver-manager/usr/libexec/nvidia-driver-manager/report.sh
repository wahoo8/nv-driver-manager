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

ndm_format_install_report()
{
    local previous_version="${1:-unknown}"
    local installed_version="${2:-unknown}"
    local result="${3:-Installation completed successfully.}"
    local reboot="${4:-Reboot required.}"
    local report_date="${5:-$(date '+%Y-%m-%d %H:%M:%S %Z')}"
    local mok_key="${NDM_MOK_KEY:-/var/lib/dkms/MOK.key}"
    local mok_cert="${NDM_MOK_CERT:-/var/lib/dkms/MOK.der}"

    printf '%s\n' 'NVIDIA Driver Manager Installation Report'
    printf '%s\n' '========================================='
    printf '\n'
    printf 'Date:              %s\n' "$report_date"
    printf 'Previous Driver:   %s\n' "$previous_version"
    printf 'Installed Driver:  %s\n' "$installed_version"
    printf '\n'

    printf '%s\n' 'DKMS'
    printf '%s\n' '----'

    if ndm_dkms_nvidia_registered; then
        ndm_dkms_nvidia_status
    else
        printf '%s\n' 'No NVIDIA DKMS registrations found.'
    fi

    printf '\n'
    printf '%s\n' 'Secure Boot'
    printf '%s\n' '-----------'

    if [[ -f "$mok_key" && -f "$mok_cert" ]]; then
        printf '%-18s %s\n' 'MOK signing files:' 'found'
        printf '%-18s %s\n' 'MOK key:' "$mok_key"
        printf '%-18s %s\n' 'MOK cert:' "$mok_cert"
    else
        printf '%-18s %s\n' 'MOK signing files:' 'missing'
    fi

    printf '\n'
    printf '%s\n' 'Initramfs'
    printf '%s\n' '---------'
    printf '%-18s %s\n' 'Updated:' 'Yes'

    printf '\n'
    printf '%s\n' 'Result'
    printf '%s\n' '------'
    printf '%s\n' "$result"
    printf '%s\n' "$reboot"
}

ndm_write_install_report()
{
    local previous_version="${1:-unknown}"
    local installed_version="${2:-unknown}"
    local result="${3:-Installation completed successfully.}"
    local reboot="${4:-Reboot required.}"
    local report_file="${5:-$NDM_INSTALL_REPORT_FILE}"
    local report_dir=""

    report_dir="$(dirname "$report_file")"
    mkdir -p "$report_dir"

    ndm_format_install_report \
        "$previous_version" \
        "$installed_version" \
        "$result" \
        "$reboot" \
        > "$report_file"

    printf '%s\n' "$report_file"
}

ndm_read_install_report()
{
    local report_file="${1:-$NDM_INSTALL_REPORT_FILE}"

    if [[ -r "$report_file" ]]; then
        cat "$report_file"
    else
        printf 'Installation report not found: %s\n' "$report_file"
    fi
}
