#!/usr/bin/env bash
# shellcheck shell=bash

_ndm_log_timestamp()
{
    date '+%Y-%m-%d %H:%M:%S'
}

_ndm_log_write()
{
    local level="$1"
    local message="$2"
    local logfile="${NDM_LOG_FILE:-${NDM_LOG_DIR:-/var/log/nvidia-driver-manager}/updater.log}"

    printf '[%s] [%s] %s\n' "$(_ndm_log_timestamp)" "$level" "$message"

    if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
        mkdir -p "$(dirname "$logfile")"
        printf '[%s] [%s] %s\n' "$(_ndm_log_timestamp)" "$level" "$message" >> "$logfile"
    fi
}

ndm_log_info()
{
    _ndm_log_write "INFO" "$*"
}

ndm_log_warn()
{
    _ndm_log_write "WARN" "$*" >&2
}

ndm_log_error()
{
    _ndm_log_write "ERROR" "$*" >&2
}

ndm_log_debug()
{
    if [[ "${NDM_DEBUG:-0}" == "1" ]]; then
        _ndm_log_write "DEBUG" "$*"
    fi
}

ndm_fatal()
{
    ndm_log_error "$*"
    exit 1
}
