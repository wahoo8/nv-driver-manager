#!/usr/bin/env bash
# shellcheck shell=bash

ndm_require_lib gui
ndm_require_lib installer
ndm_require_lib metadata
ndm_require_lib cache
ndm_require_lib version
ndm_require_lib network
ndm_require_lib report
ndm_require_lib dkms
ndm_require_lib system

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

if ! ndm_gui_install_intro \
    "$LATEST_VERSION" \
    "$INSTALLED_VERSION" \
    "$INSTALLER_PATH" \
    "${NDM_NVIDIA_KERNEL_MODULE_TYPE:-open}"; then
    ndm_log_info "Installation cancelled by user."
    exit 0
fi

HELPER="/usr/libexec/nvidia-driver-manager/nvinstall.sh"
INSTALL_LOG="/var/log/nvidia-driver-manager/install.log"
REPORT_FILE="/var/log/nvidia-driver-manager/install-report.txt"

ndm_log_info "Starting privileged installation helper."

ndm_gui_install_start

if ! pkexec "$HELPER" "$INSTALLER_PATH" "$LATEST_VERSION"; then
    printf '\n'
    printf 'NV Driver Manager installation failed.\n'
    printf '\n'
    printf 'See:\n'
    printf '  %s\n' "$INSTALL_LOG"
    printf '  /var/log/nvidia-installer.log\n'
    exit 1
fi

printf '\n'
printf 'NV Driver Manager installation completed.\n'
printf '\n'
printf 'Report:\n'
printf '  %s\n' "$REPORT_FILE"
printf '\n'
printf 'Logs:\n'
printf '  %s\n' "$INSTALL_LOG"
printf '  /var/log/nvidia-installer.log\n'
printf '\n'
printf 'A reboot is strongly recommended.\n'
printf 'Run:\n'
printf '  sudo reboot\n'

exit 0
