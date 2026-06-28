#!/usr/bin/env bash
# shellcheck shell=bash

ndm_dkms_bin()
{
    ndm_command_path dkms
}

ndm_dkms_status()
{
    local dkms_bin

    dkms_bin="$(ndm_dkms_bin)" || return 1
    "$dkms_bin" status 2>/dev/null || true
}

ndm_dkms_nvidia_status()
{
    ndm_dkms_status | grep -i '^nvidia/' || true
}

ndm_dkms_nvidia_registered()
{
    ndm_dkms_nvidia_status | grep -qi '^nvidia/'
}

ndm_fix_pahole_permissions()
{
    local dkms_tree="${1:-/var/lib/dkms}"

    if [[ ! -d "$dkms_tree/nvidia" ]]; then
        return 0
    fi

    find "$dkms_tree/nvidia" \
        -type f \
        -name 'pahole.sh' \
        -exec chmod 0755 {} \;
}

ndm_dkms_latest_nvidia_version()
{
    ndm_dkms_nvidia_status |
        awk -F'[,/]' '
            $1 ~ /^nvidia$/ {
                print $2
            }
        ' |
        sort -V |
        tail -n 1
}

ndm_dkms_kernel_has_nvidia()
{
    local kernel_version="$1"

    ndm_dkms_nvidia_status |
        grep -F ", ${kernel_version}," |
        grep -qi 'installed'
}

ndm_dkms_verify_all_kernels()
{
    local kernel_version=""
    local missing=0

    while IFS= read -r kernel_version; do
        if ndm_dkms_kernel_has_nvidia "$kernel_version"; then
            printf '✓ NVIDIA DKMS installed for %s\n' "$kernel_version"
        else
            printf '! NVIDIA DKMS missing for %s\n' "$kernel_version"
            missing=$((missing + 1))
        fi
    done < <(ndm_installed_kernels)

    (( missing == 0 ))
}
