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

ndm_gui_install_intro()
{
    local latest_version="$1"
    local installed_version="$2"
    local installer_path="$3"
    local kernel_module_type="${4:-open}"

    ndm_gui_question \
        "NVIDIA Driver Manager" \
        "Ready to install NVIDIA driver.

Installed version: $installed_version
New version:       $latest_version

Kernel modules:   $kernel_module_type
DKMS:             enabled
Secure Boot:      MOK signing configured
Initramfs:        rebuild enabled

Installer:
$installer_path

Continue?"
}

ndm_gui_install_start()
{
    ndm_gui_info \
        "NVIDIA Driver Manager" \
        "The NVIDIA installer will now start.

Most options have already been configured.

The installer may still display NVIDIA-specific prompts.

When it finishes, NVIDIA Driver Manager will show a summary."
}

ndm_gui_install_complete()
{
    local summary="$1"

    ndm_gui_info \
        "NVIDIA Driver Manager - Installation Complete" \
        "$summary"
}

ndm_gui_reboot_prompt()
{
    ndm_gui_question \
        "NVIDIA Driver Manager" \
        "Installation completed successfully.

A reboot is strongly recommended.

Reboot now?"
}
