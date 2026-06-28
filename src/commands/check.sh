#!/usr/bin/env bash
# shellcheck shell=bash

# shellcheck disable=SC1091
source "$NDM_LIB_DIR/metadata.sh"
# shellcheck disable=SC1091
source "$NDM_LIB_DIR/version.sh"

ndm_load_driver_metadata

INSTALLED_VERSION="$(ndm_get_installed_version)" || \
    ndm_fatal "Unable to determine installed NVIDIA driver version."

LATEST_VERSION="$NDM_DRIVER_VERSION"
STATUS="$(ndm_version_status "$INSTALLED_VERSION" "$LATEST_VERSION")"

cat <<EOF
NVIDIA Driver Manager $NDM_VERSION

Installed Driver : $INSTALLED_VERSION
Latest Driver    : $LATEST_VERSION
Download URL     : $NDM_DRIVER_DOWNLOAD_URL

Status           : $STATUS
EOF
