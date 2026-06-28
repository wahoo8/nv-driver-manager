#!/usr/bin/env bash
# shellcheck shell=bash

ndm_parse_latest_production_version()
{
    local html_file="$1"

    if [[ ! -r "$html_file" ]]; then
        ndm_fatal "Cannot read NVIDIA page cache: $html_file"
    fi

    xmllint \
        --html \
        --xpath 'string(//body)' \
        "$html_file" \
        2>/dev/null |
        tr '\n' ' ' |
        sed -E 's/[[:space:]]+/ /g' |
        grep -oE 'Latest Production Branch Version[^0-9]*[0-9]+(\.[0-9]+)+' |
        grep -oE '[0-9]+(\.[0-9]+)+' |
        head -n 1
}
