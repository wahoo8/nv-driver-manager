#!/usr/bin/env bash
# shellcheck shell=bash

ndm_metadata_cache_valid()
{
    local page_cache="$1"
    local now
    local modified
    local age

    [[ -f "$page_cache" ]] || return 1

    now="$(date +%s)"
    modified="$(stat -c %Y "$page_cache" 2>/dev/null)" || return 1
    age=$((now - modified))

    (( age < NDM_METADATA_MAX_AGE ))
}

ndm_metadata_write_state()
{
    local state_file

    state_file="$(ndm_cache_state_path "last-update")"

    {
        printf 'timestamp=%s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
        printf 'version=%s\n' "$NDM_DRIVER_VERSION"
        printf 'download_url=%s\n' "$NDM_DRIVER_DOWNLOAD_URL"
    } > "$state_file"
}

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

    if ndm_metadata_cache_valid "$page_cache"; then
        ndm_log_info "Using cached NVIDIA metadata."
    else
        ndm_log_info "Refreshing NVIDIA metadata."
        ndm_download_file "$NDM_NVIDIA_UNIX_URL" "$page_cache"
    fi

    ndm_parse_driver_metadata "$page_cache"

    if [[ -z "$NDM_DRIVER_VERSION" ]]; then
        ndm_fatal "Unable to determine latest NVIDIA Production Branch version."
    fi

    if [[ -z "$NDM_DRIVER_DOWNLOAD_URL" ]]; then
        ndm_fatal "Unable to determine NVIDIA driver download URL."
    fi

    ndm_metadata_write_state
}
