#!/usr/bin/env bash
# shellcheck shell=bash

ndm_command_path()
{
    local command_name="$1"
    local candidate=""

    if candidate="$(command -v "$command_name" 2>/dev/null)"; then
        printf '%s\n' "$candidate"
        return 0
    fi

    for candidate in \
        "/usr/sbin/${command_name}" \
        "/sbin/${command_name}" \
        "/usr/local/sbin/${command_name}"
    do
        if [[ -x "$candidate" ]]; then
            printf '%s\n' "$candidate"
            return 0
        fi
    done

    return 1
}

ndm_command_exists()
{
    ndm_command_path "$1" >/dev/null 2>&1
}

ndm_require_command()
{
    local command_name="$1"

    if ! ndm_command_exists "$command_name"; then
        ndm_fatal "Required command not found: $command_name"
    fi
}

ndm_is_root()
{
    [[ "${EUID:-$(id -u)}" -eq 0 ]]
}

ndm_require_root()
{
    if ! ndm_is_root; then
        ndm_fatal "This operation must be run as root."
    fi
}

ndm_is_graphical_session()
{
    [[ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]]
}

ndm_secure_boot_enabled()
{
    if ! ndm_command_exists mokutil; then
        return 2
    fi

    mokutil --sb-state 2>/dev/null | grep -qi 'SecureBoot enabled'
}

ndm_kernel_headers_installed()
{
    local kernel_version="$1"

    [[ -d "/lib/modules/${kernel_version}/build" ]]
}

ndm_installed_kernels()
{
    local kernel_image

    for kernel_image in /boot/vmlinuz-*; do
        [[ -e "$kernel_image" ]] || continue
        basename "$kernel_image" | sed 's/^vmlinuz-//'
    done | sort -V
}

ndm_available_kb()
{
    local path="${1:-/}"
    df -Pk "$path" | awk 'NR == 2 {print $4}'
}

ndm_require_min_free_kb()
{
    local path="$1"
    local required_kb="$2"
    local available_kb

    available_kb="$(ndm_available_kb "$path")"

    if (( available_kb < required_kb )); then
        ndm_fatal "Insufficient free space at $path. Required ${required_kb}KB, available ${available_kb}KB."
    fi
}
