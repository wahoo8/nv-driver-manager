#!/usr/bin/env bash
# shellcheck shell=bash

_log_timestamp()
{
    date '+%Y-%m-%d %H:%M:%S'
}

_log_write()
{
    local level="$1"
    local message="$2"
    local logfile="${NDM_LOG_FILE:-${NDM_LOG_DIR:-/var/log/nvidia-driver-manager}/updater.log}"

    printf '[%s] [%s] %s\n' "$(_log_timestamp)" "$level" "$message"

    if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
        mkdir -p "$(dirname "$logfile")"
        printf '[%s] [%s] %s\n' "$(_log_timestamp)" "$level" "$message" >> "$logfile"
    fi
}

log_info()
{
    _log_write "INFO" "$*"
}

log_warn()
{
    _log_write "WARN" "$*" >&2
}

log_error()
{
    _log_write "ERROR" "$*" >&2
}

log_debug()
{
    if [[ "${NDM_DEBUG:-0}" == "1" ]]; then
        _log_write "DEBUG" "$*"
    fi
}

fatal()
{
    log_error "$*"
    exit 1
}
