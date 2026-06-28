#!/usr/bin/env bash
# shellcheck shell=bash

ndm_require_lib cache
ndm_require_lib metadata
ndm_require_lib network
ndm_require_lib version

ndm_cache_init
ndm_load_driver_metadata

INSTALLED_VERSION="$(ndm_get_installed_version)" || \
    ndm_fatal "Unable to determine installed NVIDIA driver version."

LATEST_VERSION="$NDM_DRIVER_VERSION"
DOWNLOAD_URL="$NDM_DRIVER_DOWNLOAD_URL"
INSTALLER_FILE="NVIDIA-Linux-x86_64-${LATEST_VERSION}.run"
INSTALLER_PATH="$(ndm_cache_download_path "$INSTALLER_FILE")"

if ! ndm_version_is_newer "$LATEST_VERSION" "$INSTALLED_VERSION"; then
    cat <<EOF
NVIDIA Driver Manager $NDM_VERSION

Installed Driver : $INSTALLED_VERSION
Latest Driver    : $LATEST_VERSION

Status           : Up to date
Download         : Not required
EOF
    exit 0
fi

if [[ -s "$INSTALLER_PATH" ]]; then
    cat <<EOF
NVIDIA Driver Manager $NDM_VERSION

Installed Driver : $INSTALLED_VERSION
Latest Driver    : $LATEST_VERSION

Status           : Update available
Download         : Already cached
Installer        : $INSTALLER_PATH
EOF
    exit 0
fi

ndm_log_info "Downloading NVIDIA driver $LATEST_VERSION."
ndm_download_file "$DOWNLOAD_URL" "$INSTALLER_PATH"
chmod 0755 "$INSTALLER_PATH"

ndm_cache_cleanup_downloads "$INSTALLED_VERSION" "$LATEST_VERSION"

cat <<EOF
NVIDIA Driver Manager $NDM_VERSION

Installed Driver : $INSTALLED_VERSION
Latest Driver    : $LATEST_VERSION

Status           : Update available
Download         : Complete
Installer        : $INSTALLER_PATH
EOF
