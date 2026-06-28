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

ndm_health_summary
