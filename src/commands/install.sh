#!/usr/bin/env bash
# shellcheck shell=bash

ndm_require_lib gui
ndm_require_lib health
ndm_require_lib installer
ndm_require_lib metadata
ndm_require_lib cache
ndm_require_lib version

ndm_cache_init

printf 'Preparing NVIDIA driver installation...\n\n'

# Refresh metadata
ndm_load_driver_metadata

LATEST_VERSION="$NDM_DRIVER_VERSION"

# Verify installer exists
INSTALLED_VERSION="$(ndm_get_installed_version)" || \
    ndm_fatal "Unable to determine installed NVIDIA driver version."

if ! ndm_version_is_newer "$LATEST_VERSION" "$INSTALLED_VERSION"; then
    printf 'NVIDIA Driver Manager %s\n\n' "$NDM_VERSION"
    printf 'Installed Driver : %s\n' "$INSTALLED_VERSION"
    printf 'Latest Driver    : %s\n\n' "$LATEST_VERSION"
    printf 'Status           : Up to date\n'
    printf 'Install          : Not required\n'
    exit 0
fi

if ! ndm_installer_exists "$LATEST_VERSION"; then
    ndm_fatal "Installer for NVIDIA ${LATEST_VERSION} is not cached. Run 'nvidia-driver-manager download' first."
fi

INSTALLER_PATH="$(ndm_installer_require_for_version "$LATEST_VERSION")"

MESSAGE=$(cat <<EOF
NVIDIA Driver Version: $LATEST_VERSION

Installer:
$INSTALLER_PATH

The installer is ready.

Continue with installation?
EOF
)

if ! ndm_gui_question "NVIDIA Driver Manager" "$MESSAGE"; then
    ndm_log_info "Installation cancelled by user."
    exit 0
fi

printf "\n"
printf "Pre-flight checks completed successfully.\n"
printf "Installer path:\n"
printf "  %s\n" "$INSTALLER_PATH"
printf "\n"
printf "The actual installation phase will be implemented next.\n"
