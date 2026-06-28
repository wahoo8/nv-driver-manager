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

LATEST_VERSION="$(ndm_parse_latest_production_version "$PAGE_CACHE")"

if [[ -z "$LATEST_VERSION" ]]; then
    ndm_fatal "Unable to determine latest NVIDIA Production Branch version."
fi

STATUS="$(ndm_version_status "$INSTALLED_VERSION" "$LATEST_VERSION")"

cat <<EOF
NVIDIA Driver Manager $NDM_VERSION

Installed Driver : $INSTALLED_VERSION
Latest Driver    : $LATEST_VERSION

Status           : $STATUS
EOF
