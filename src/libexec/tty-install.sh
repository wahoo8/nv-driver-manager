#!/usr/bin/env bash

set -Eeuo pipefail
IFS=$'\n\t'

INSTALLER_PATH="${1:-}"

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    echo "ERROR: must run as root."
    exit 1
fi

if [[ -z "$INSTALLER_PATH" || ! -f "$INSTALLER_PATH" ]]; then
    echo "ERROR: installer not found: $INSTALLER_PATH"
    exit 1
fi

clear
echo "NVIDIA Driver Manager"
echo
echo "Switching to text mode for NVIDIA driver installation."
echo "Your graphical session will stop."
echo
echo "Press Enter to continue, or Ctrl+C to cancel."
read -r

systemctl isolate multi-user.target

/usr/libexec/nvidia-driver-manager/nvinstall.sh "$INSTALLER_PATH"

echo
echo "Installation complete."
echo "Reboot is strongly recommended."
echo
echo "Press Enter to reboot now, or Ctrl+C to stay in text mode."
read -r

systemctl reboot
