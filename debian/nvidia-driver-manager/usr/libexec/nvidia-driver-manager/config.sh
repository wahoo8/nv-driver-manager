#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck disable=SC2034

NDM_NAME="nvidia-driver-manager"
NDM_VERSION="0.1.0"

NDM_CONFIG_FILE="${NDM_CONFIG_FILE:-/etc/nvidia-driver-manager.conf}"
NDM_LOG_DIR="${NDM_LOG_DIR:-/var/log/nvidia-driver-manager}"
NDM_CACHE_DIR="${NDM_CACHE_DIR:-${HOME}/.cache/nvidia-driver-manager}"

NDM_NVIDIA_UNIX_URL="${NDM_NVIDIA_UNIX_URL:-https://www.nvidia.com/en-us/drivers/unix/}"
NDM_DOWNLOAD_BASE_URL="${NDM_DOWNLOAD_BASE_URL:-https://us.download.nvidia.com/XFree86/Linux-x86_64}"

NDM_KEEP_INSTALLERS="${NDM_KEEP_INSTALLERS:-2}"
NDM_DEBUG="${NDM_DEBUG:-0}"

load_config()
{
    if [[ -r "$NDM_CONFIG_FILE" ]]; then
        # shellcheck disable=SC1090
        source "$NDM_CONFIG_FILE"
    fi
}

ensure_runtime_dirs()
{
    mkdir -p "$NDM_CACHE_DIR"
}
