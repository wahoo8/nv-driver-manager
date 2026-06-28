#!/usr/bin/env bash
# shellcheck shell=bash

ndm_cache_init()
{
    NDM_CACHE_PAGES_DIR="${NDM_CACHE_DIR}/${NDM_CACHE_PAGES_SUBDIR}"
    NDM_CACHE_DOWNLOADS_DIR="${NDM_CACHE_DIR}/${NDM_CACHE_DOWNLOADS_SUBDIR}"
    NDM_CACHE_STATE_DIR="${NDM_CACHE_DIR}/${NDM_CACHE_STATE_SUBDIR}"
    NDM_CACHE_CHECKSUMS_DIR="${NDM_CACHE_DIR}/${NDM_CACHE_CHECKSUMS_SUBDIR}"
    NDM_CACHE_LOGS_DIR="${NDM_CACHE_DIR}/${NDM_CACHE_LOGS_SUBDIR}"

    mkdir -p \
        "$NDM_CACHE_PAGES_DIR" \
        "$NDM_CACHE_DOWNLOADS_DIR" \
        "$NDM_CACHE_STATE_DIR" \
        "$NDM_CACHE_CHECKSUMS_DIR" \
        "$NDM_CACHE_LOGS_DIR"
}

ndm_cache_page_path()
{
    local name="$1"
    printf '%s/%s\n' "$NDM_CACHE_PAGES_DIR" "$name"
}

ndm_cache_download_path()
{
    local filename="$1"
    printf '%s/%s\n' "$NDM_CACHE_DOWNLOADS_DIR" "$filename"
}

ndm_cache_state_path()
{
    local name="$1"
    printf '%s/%s\n' "$NDM_CACHE_STATE_DIR" "$name"
}

ndm_cache_checksum_path()
{
    local name="$1"
    printf '%s/%s\n' "$NDM_CACHE_CHECKSUMS_DIR" "$name"
}

ndm_cache_log_path()
{
    local name="$1"
    printf '%s/%s\n' "$NDM_CACHE_LOGS_DIR" "$name"
}

ndm_cache_cleanup_downloads()
{
    local current_version="${1:-}"
    local newest_version="${2:-}"
    local installer=""

    find "$NDM_CACHE_DOWNLOADS_DIR" \
        -maxdepth 1 \
        -type f \
        -name 'NVIDIA-Linux-x86_64-*.run' |
    while IFS= read -r installer; do
        case "$installer" in
            *-"${current_version}".run|*-"${newest_version}".run)
                ;;
            *)
                rm -f -- "$installer"
                ;;
        esac
    done
}
