#!/usr/bin/env bash
# shellcheck shell=bash

ndm_load_driver_metadata()
{
    local page_cache=""

    # shellcheck disable=SC1091
    source "$NDM_LIB_DIR/cache.sh"
    # shellcheck disable=SC1091
    source "$NDM_LIB_DIR/network.sh"
    # shellcheck disable=SC1091
    source "$NDM_LIB_DIR/parser.sh"

    ndm_cache_init

    page_cache="$(ndm_cache_page_path "nvidia-unix.html")"

    ndm_log_info "Refreshing NVIDIA UNIX driver metadata."

    ndm_download_file "$NDM_NVIDIA_UNIX_URL" "$page_cache"
    ndm_parse_driver_metadata "$page_cache"

    if [[ -z "$NDM_DRIVER_VERSION" ]]; then
        ndm_fatal "Unable to determine latest NVIDIA Production Branch version."
    fi

    if [[ -z "$NDM_DRIVER_DOWNLOAD_URL" ]]; then
        ndm_fatal "Unable to determine NVIDIA driver download URL."
    fi
}
