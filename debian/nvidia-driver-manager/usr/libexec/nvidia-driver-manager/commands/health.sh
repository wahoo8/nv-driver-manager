#!/usr/bin/env bash
# shellcheck shell=bash

ndm_require_lib system
ndm_require_lib version
ndm_require_lib health

printf 'NVIDIA Driver Manager Health Report\n\n'

ndm_health_check_nvidia_driver
ndm_health_check_dkms

ndm_health_check_command curl
ndm_health_check_command xmllint libxml2-utils
ndm_health_check_optional_command zenity
ndm_health_check_optional_command pkexec

ndm_health_check_secure_boot
ndm_health_check_kernel_headers

printf '\nInstallation logs:\n'

if [[ -r /var/log/nvidia-driver-manager/install.log ]]; then
    ndm_health_pass "install.log found"
else
    ndm_health_warn "install.log not found"
fi

if [[ -r /var/log/nvidia-driver-manager/install-report.txt ]]; then
    ndm_health_pass "install-report.txt found"
else
    ndm_health_warn "install-report.txt not found"
fi

if [[ -r /var/log/nvidia-driver-manager/history.log ]]; then
    ndm_health_pass "history.log found"
else
    ndm_health_warn "history.log not found"
fi

ndm_health_summary
