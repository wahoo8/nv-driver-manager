#!/usr/bin/env bash
# shellcheck shell=bash

ndm_installer_filename()
{
    local version="$1"

    printf 'NVIDIA-Linux-x86_64-%s.run\n' "$version"
}

ndm_installer_path_for_version()
{
    local version="$1"
    local filename

    filename="$(ndm_installer_filename "$version")"

    ndm_cache_download_path "$filename"
}

ndm_installer_exists()
{
    local version="$1"
    local installer_path

    installer_path="$(ndm_installer_path_for_version "$version")"

    [[ -s "$installer_path" ]]
}

ndm_installer_make_executable()
{
    local installer_path="$1"

    [[ -f "$installer_path" ]] || return 1

    chmod 0755 "$installer_path"
}

ndm_installer_latest_cached()
{
    find "$NDM_CACHE_DOWNLOADS_DIR" \
        -maxdepth 1 \
        -type f \
        -name 'NVIDIA-Linux-x86_64-*.run' \
        -printf '%f\n' |
        sed -E 's/^NVIDIA-Linux-x86_64-//; s/\.run$//' |
        sort -V |
        tail -n 1
}

ndm_installer_latest_cached_path()
{
    local version

    version="$(ndm_installer_latest_cached)"

    [[ -n "$version" ]] || return 1

    ndm_installer_path_for_version "$version"
}

ndm_installer_require_for_version()
{
    local version="$1"
    local installer_path

    installer_path="$(ndm_installer_path_for_version "$version")"

    if [[ ! -s "$installer_path" ]]; then
        ndm_fatal "NVIDIA installer not found in cache: $installer_path"
    fi

    ndm_installer_make_executable "$installer_path"

    printf '%s\n' "$installer_path"
}
