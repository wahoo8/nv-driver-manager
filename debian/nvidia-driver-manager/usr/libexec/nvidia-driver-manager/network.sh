#!/usr/bin/env bash
# shellcheck shell=bash

ndm_download_file()
{
    local url="$1"
    local output="$2"

    curl \
        --fail \
        --silent \
        --show-error \
        --location \
        --retry 3 \
        --retry-delay 2 \
        --connect-timeout 15 \
        --max-time 60 \
        --output "$output" \
        "$url"
}
