#!/usr/bin/env bash
# shellcheck shell=bash

ndm_gui_available()
{
    command -v zenity >/dev/null 2>&1 &&
        [[ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]]
}

ndm_gui_info()
{
    local title="$1"
    local message="$2"

    if ndm_gui_available; then
        zenity --info --title="$title" --text="$message" --width=500
    else
        printf '%s\n\n%s\n' "$title" "$message"
    fi
}

ndm_gui_warning()
{
    local title="$1"
    local message="$2"

    if ndm_gui_available; then
        zenity --warning --title="$title" --text="$message" --width=500
    else
        printf 'WARNING: %s\n\n%s\n' "$title" "$message" >&2
    fi
}

ndm_gui_error()
{
    local title="$1"
    local message="$2"

    if ndm_gui_available; then
        zenity --error --title="$title" --text="$message" --width=500
    else
        printf 'ERROR: %s\n\n%s\n' "$title" "$message" >&2
    fi
}

ndm_gui_question()
{
    local title="$1"
    local message="$2"

    if ndm_gui_available; then
        zenity --question --title="$title" --text="$message" --width=500
    else
        printf '%s\n\n%s\n\nProceed? [y/N]: ' "$title" "$message" >&2
        read -r answer
        case "$answer" in
            y|Y|yes|YES|Yes)
                return 0
                ;;
            *)
                return 1
                ;;
        esac
    fi
}

ndm_gui_notify()
{
    local title="$1"
    local message="$2"

    if command -v notify-send >/dev/null 2>&1 &&
        [[ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]]; then
        notify-send "$title" "$message"
    else
        ndm_gui_info "$title" "$message"
    fi
}
