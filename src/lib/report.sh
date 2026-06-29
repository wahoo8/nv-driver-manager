#!/usr/bin/env bash
# shellcheck shell=bash

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
