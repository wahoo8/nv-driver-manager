#!/usr/bin/env bash
# shellcheck shell=bash

ndm_get_installed_version()
{
    local version=""

    if command -v nvidia-smi >/dev/null 2>&1; then
        version="$(
            nvidia-smi \
                --query-gpu=driver_version \
                --format=csv,noheader \
                2>/dev/null |
            head -n 1 |
            tr -d '[:space:]'
        )"
    fi

    if [[ -z "$version" ]] && command -v modinfo >/dev/null 2>&1; then
        version="$(
            modinfo -F version nvidia 2>/dev/null |
            head -n 1 |
            tr -d '[:space:]'
        )"
    fi

    if [[ -z "$version" ]]; then
        return 1
    fi

    printf '%s\n' "$version"
}

ndm_normalize_version()
{
    local version="$1"

    printf '%s\n' "$version" |
        sed -E 's/[^0-9.].*$//' |
        awk -F. '
            {
                major = ($1 == "" ? 0 : $1)
                minor = ($2 == "" ? 0 : $2)
                patch = ($3 == "" ? 0 : $3)
                printf "%d.%d.%d\n", major, minor, patch
            }
        '
}

ndm_compare_versions()
{
    local left
    local right

    left="$(ndm_normalize_version "$1")"
    right="$(ndm_normalize_version "$2")"

    if [[ "$left" == "$right" ]]; then
        return 0
    fi

    if dpkg --compare-versions "$left" gt "$right"; then
        return 1
    fi

    return 2
}

ndm_version_is_newer()
{
    local candidate="$1"
    local current="$2"

    dpkg --compare-versions \
        "$(ndm_normalize_version "$candidate")" \
        gt \
        "$(ndm_normalize_version "$current")"
}
