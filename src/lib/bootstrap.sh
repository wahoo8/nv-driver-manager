#!/usr/bin/env bash
# shellcheck shell=bash

ndm_bootstrap()
{
    local script_dir
    local dev_lib_dir
    local installed_lib_dir

script_dir="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
installed_lib_dir="/usr/libexec/nvidia-driver-manager"

dev_lib_dir=""

if [[ -d "$script_dir/../lib" ]]; then
    dev_lib_dir="$(cd "$script_dir/../lib" && pwd)"
fi

if [[ -n "$dev_lib_dir" && -f "$dev_lib_dir/config.sh" ]]; then
    NDM_LIB_DIR="$dev_lib_dir"
else
    NDM_LIB_DIR="$installed_lib_dir"
fi

    # shellcheck disable=SC1091
    source "$NDM_LIB_DIR/config.sh"

    # shellcheck disable=SC1091
    source "$NDM_LIB_DIR/logging.sh"

    ndm_load_config
    ndm_ensure_runtime_dirs
}

ndm_require_lib()
{
    local library_name="$1"
    local library_path="$NDM_LIB_DIR/${library_name}.sh"

    if [[ ! -r "$library_path" ]]; then
        printf 'Required library not found: %s\n' "$library_path" >&2
        exit 1
    fi

    # shellcheck disable=SC1090
    source "$library_path"
}
