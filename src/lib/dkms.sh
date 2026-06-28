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

ndm_fix_pahole_permissions()
{
    find /var/lib/dkms/nvidia \
        -type f \
        -name pahole.sh \
        -exec chmod 0755 {} \; \
        2>/dev/null || true
}

ndm_dkms_kernel_has_nvidia()
{
    local kernel_version="$1"

    ndm_dkms_nvidia_status |
        grep -F ", ${kernel_version}," |
        grep -qi 'installed'
}

ndm_dkms_build_kernel()
{
    local dkms_version="$1"
    local kernel_version="$2"
    local dkms_bin

    dkms_bin="$(ndm_dkms_bin)" || return 1

    if ndm_dkms_kernel_has_nvidia "$kernel_version"; then
        ndm_log_info "NVIDIA DKMS already installed for $kernel_version."
        return 0
    fi

    ndm_log_info "Building NVIDIA DKMS $dkms_version for $kernel_version."
    ndm_fix_pahole_permissions

    "$dkms_bin" build "nvidia/$dkms_version" -k "$kernel_version"

    ndm_fix_pahole_permissions

    ndm_log_info "Installing NVIDIA DKMS $dkms_version for $kernel_version."
    "$dkms_bin" install "nvidia/$dkms_version" -k "$kernel_version"

    ndm_dkms_kernel_has_nvidia "$kernel_version"
}

ndm_dkms_build_all_kernels()
{
    local dkms_version="${1:-}"
    local kernel_version=""
    local failures=0

    if [[ -z "$dkms_version" ]]; then
        dkms_version="$(ndm_dkms_latest_nvidia_version)"
    fi

    if [[ -z "$dkms_version" ]]; then
        ndm_fatal "Unable to determine NVIDIA DKMS version."
    fi

    while IFS= read -r kernel_version; do
        if ndm_dkms_build_kernel "$dkms_version" "$kernel_version"; then
            printf '✓ NVIDIA DKMS installed for %s\n' "$kernel_version"
        else
            printf '✗ NVIDIA DKMS failed for %s\n' "$kernel_version"
            failures=$((failures + 1))
        fi
    done < <(ndm_installed_kernels)

    (( failures == 0 ))
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

ndm_dkms_report()
{
    printf 'NVIDIA DKMS status:\n'

    if ndm_dkms_nvidia_registered; then
        ndm_dkms_nvidia_status | sed 's/^/  /'
    else
        printf '  No NVIDIA DKMS registrations found.\n'
    fi
}
