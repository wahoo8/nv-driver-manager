#!/usr/bin/env bash
# shellcheck shell=bash

ndm_require_lib gui
ndm_require_lib installer
ndm_require_lib metadata
ndm_require_lib cache
ndm_require_lib version
ndm_require_lib network

FORCE_INSTALL=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --force|-f)
            FORCE_INSTALL=1
            shift
            ;;
        *)
            ndm_fatal "Unknown install option: $1"
            ;;
    esac
done

ndm_cache_init

printf 'Preparing NVIDIA driver installation...\n\n'

ndm_load_driver_metadata

LATEST_VERSION="$NDM_DRIVER_VERSION"

INSTALLED_VERSION="$(ndm_get_installed_version)" || \
    ndm_fatal "Unable to determine installed NVIDIA driver version."

if ! ndm_version_is_newer "$LATEST_VERSION" "$INSTALLED_VERSION" &&
   [[ "$FORCE_INSTALL" != "1" ]]; then
    printf 'NVIDIA Driver Manager %s\n\n' "$NDM_VERSION"
    printf 'Installed Driver : %s\n' "$INSTALLED_VERSION"
    printf 'Latest Driver    : %s\n\n' "$LATEST_VERSION"
    printf 'Status           : Up to date\n'
    printf 'Install          : Not required\n'
    exit 0
fi

INSTALLER_PATH="$(ndm_installer_path_for_version "$LATEST_VERSION")"

if ! ndm_installer_exists "$LATEST_VERSION"; then
    if [[ "$FORCE_INSTALL" == "1" ]]; then
        ndm_log_info "Installer not cached; downloading NVIDIA $LATEST_VERSION."
        ndm_log_info "Downloading from: $NDM_DRIVER_DOWNLOAD_URL"
        ndm_log_info "Downloading to: $INSTALLER_PATH"

        ndm_download_file "$NDM_DRIVER_DOWNLOAD_URL" "$INSTALLER_PATH"
        ndm_installer_make_executable "$INSTALLER_PATH"
    else
        ndm_fatal "Installer for NVIDIA ${LATEST_VERSION} is not cached. Run 'nvidia-driver-manager download' first."
    fi
fi

INSTALLER_PATH="$(ndm_installer_require_for_version "$LATEST_VERSION")"

MESSAGE="$(cat <<EOF
NVIDIA Driver Version: $LATEST_VERSION
Installed Version: $INSTALLED_VERSION
Force Install: $FORCE_INSTALL

Installer:
$INSTALLER_PATH

Continue with installation?
EOF
)"

if ! ndm_gui_question "NVIDIA Driver Manager" "$MESSAGE"; then
    ndm_log_info "Installation cancelled by user."
    exit 0
fi

HELPER="/usr/libexec/nvidia-driver-manager/nvinstall.sh"

ndm_log_info "Starting privileged installation helper."

INSTALL_LOG="/var/log/nvidia-driver-manager/install.log"

if ndm_gui_available; then
    (
        echo "10"
        echo "# Starting NVIDIA installer..."

        if pkexec "$HELPER" "$INSTALLER_PATH"; then
            echo "90"
            echo "# Installation helper completed."
            sleep 1
            echo "100"
        else
            echo "100"
            exit 1
        fi
    ) | zenity \
        --progress \
        --title="NVIDIA Driver Manager" \
        --text="Installing NVIDIA driver..." \
        --percentage=0 \
        --auto-close \
        --width=500

    RESULT=${PIPESTATUS[0]}
else
    pkexec "$HELPER" "$INSTALLER_PATH"
    RESULT=$?
fi

if (( RESULT != 0 )); then
    ndm_gui_error \
        "NVIDIA Driver Manager" \
        "Installation failed.

See logs:

$INSTALL_LOG

/var/log/nvidia-installer.log"
    exit 1
fi

if ndm_gui_question \
    "NVIDIA Driver Manager" \
    "Installation completed successfully.

A reboot is strongly recommended.

Reboot now?"; then
    pkexec systemctl reboot
else
    ndm_gui_info \
        "NVIDIA Driver Manager" \
        "Please reboot before using the newly installed NVIDIA driver."
fi
