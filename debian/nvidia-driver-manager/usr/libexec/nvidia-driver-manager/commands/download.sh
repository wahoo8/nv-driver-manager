#!/usr/bin/env bash
# shellcheck shell=bash

# shellcheck disable=SC1091
source "$NDM_LIB_DIR/cache.sh"
# shellcheck disable=SC1091
source "$NDM_LIB_DIR/network.sh"
# shellcheck disable=SC1091
source "$NDM_LIB_DIR/parser.sh"
# shellcheck disable=SC1091
source "$NDM_LIB_DIR/version.sh"

ndm_cache_init

PAGE_CACHE="$(ndm_cache_page_path "nvidia-unix.html")"

ndm_log_info "Checking NVIDIA Production Branch driver version."
ndm_download_file "$NDM_NVIDIA_UNIX_URL" "$PAGE_CACHE"

INSTALLED_VERSION="$(ndm_get_installed_version)" || \
    ndm_fatal "Unable to determine installed NVIDIA driver version."

ndm_parse_driver_metadata "$PAGE_CACHE"

LATEST_VERSION="$NDM_DRIVER_VERSION"
DOWNLOAD_URL="$NDM_DRIVER_DOWNLOAD_URL"

if [[ -z "$LATEST_VERSION" ]]; then
    ndm_fatal "Unable to determine latest NVIDIA Production Branch version."
fi

if [[ -z "$DOWNLOAD_URL" ]]; then
    ndm_fatal "Unable to determine NVIDIA driver download URL."
fi

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
