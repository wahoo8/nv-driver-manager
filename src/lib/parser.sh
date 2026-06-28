#!/usr/bin/env bash
# shellcheck shell=bash
# shellcheck disable=SC2034

NDM_DRIVER_VERSION=""
NDM_DRIVER_DOWNLOAD_URL=""
NDM_DRIVER_RELEASE_DATE=""

_ndm_html_body_text()
{
    local html_file="$1"

    xmllint \
        --html \
        --xpath 'string(//body)' \
        "$html_file" \
        2>/dev/null |
        tr '\n' ' ' |
        sed -E 's/[[:space:]]+/ /g'
}

_ndm_html_links()
{
    local html_file="$1"

    xmllint \
        --html \
        --xpath '//a/@href' \
        "$html_file" \
        2>/dev/null |
        sed -E 's/href=/\n/g' |
        tr -d '"' |
        grep -E '^https?://' || true
}

ndm_parse_latest_production_version()
{
    local html_file="$1"

    _ndm_html_body_text "$html_file" |
        grep -oE 'Latest Production Branch Version[^0-9]*[0-9]+(\.[0-9]+)+' |
        grep -oE '[0-9]+(\.[0-9]+)+' |
        head -n 1
}

ndm_parse_driver_download_url()
{
    local html_file="$1"
    local version="$2"
    local filename="NVIDIA-Linux-x86_64-${version}.run"
    local url=""

    url="$(
        _ndm_html_links "$html_file" |
            grep -F "$filename" |
            head -n 1
    )"

    if [[ -z "$url" ]]; then
        url="${NDM_DOWNLOAD_BASE_URL}/${version}/${filename}"
    fi

    printf '%s\n' "$url"
}

ndm_parse_driver_metadata()
{
    local html_file="$1"

    if [[ ! -r "$html_file" ]]; then
        ndm_fatal "Cannot read NVIDIA page cache: $html_file"
    fi

    NDM_DRIVER_VERSION="$(ndm_parse_latest_production_version "$html_file")"

    if [[ -n "$NDM_DRIVER_VERSION" ]]; then
        NDM_DRIVER_DOWNLOAD_URL="$(
            ndm_parse_driver_download_url "$html_file" "$NDM_DRIVER_VERSION"
        )"
    else
        NDM_DRIVER_DOWNLOAD_URL=""
    fi

    NDM_DRIVER_RELEASE_DATE=""
}
