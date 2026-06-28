#!/usr/bin/env bash
# shellcheck shell=bash

NDM_HEALTH_PASS_COUNT=0
NDM_HEALTH_WARN_COUNT=0
NDM_HEALTH_FAIL_COUNT=0

ndm_health_pass()
{
    printf '✓ %s\n' "$1"
    NDM_HEALTH_PASS_COUNT=$((NDM_HEALTH_PASS_COUNT + 1))
}

ndm_health_warn()
{
    printf '! %s\n' "$1"
    NDM_HEALTH_WARN_COUNT=$((NDM_HEALTH_WARN_COUNT + 1))
}

ndm_health_fail()
{
    printf '✗ %s\n' "$1"
    NDM_HEALTH_FAIL_COUNT=$((NDM_HEALTH_FAIL_COUNT + 1))
}

ndm_health_check_command()
{
    local command_name="$1"
    local package_hint="${2:-}"

    if ndm_command_exists "$command_name"; then
        ndm_health_pass "$command_name found: $(ndm_command_path "$command_name")"
    elif [[ -n "$package_hint" ]]; then
        ndm_health_fail "$command_name not found; install $package_hint"
    else
        ndm_health_fail "$command_name not found"
    fi
}

ndm_health_check_optional_command()
{
    local command_name="$1"
    local package_hint="${2:-}"

    if ndm_command_exists "$command_name"; then
        ndm_health_pass "$command_name found: $(ndm_command_path "$command_name")"
    elif [[ -n "$package_hint" ]]; then
        ndm_health_warn "$command_name not found; install $package_hint"
    else
        ndm_health_warn "$command_name not found"
    fi
}

ndm_health_check_nvidia_driver()
{
    local installed_version=""

    if ndm_command_exists nvidia-smi; then
        ndm_health_pass "nvidia-smi found: $(ndm_command_path nvidia-smi)"
    else
        ndm_health_fail "nvidia-smi not found"
    fi

    if installed_version="$(ndm_get_installed_version)"; then
        ndm_health_pass "NVIDIA driver detected: $installed_version"
    else
        ndm_health_fail "Unable to detect NVIDIA driver version"
    fi
}

ndm_health_check_dkms()
{
    local dkms_bin=""
    local dkms_status=""

    if dkms_bin="$(ndm_command_path dkms)"; then
        ndm_health_pass "DKMS found: $dkms_bin"

        dkms_status="$("$dkms_bin" status 2>/dev/null || true)"

        if printf '%s\n' "$dkms_status" | grep -qi 'nvidia'; then
            ndm_health_pass "NVIDIA module registered with DKMS"
            printf '\nNVIDIA DKMS status:\n'
            printf '%s\n' "$dkms_status" | grep -i 'nvidia' | sed 's/^/  /'
        else
            ndm_health_warn "DKMS found, but NVIDIA module is not registered"
            if [[ -n "$dkms_status" ]]; then
                printf '%s\n' "$dkms_status"
            fi
        fi
    else
        ndm_health_fail "DKMS not found"
    fi
}

ndm_health_check_secure_boot()
{
    local mokutil_bin=""
    local sb_state=""

    if mokutil_bin="$(ndm_command_path mokutil)"; then
        sb_state="$("$mokutil_bin" --sb-state 2>/dev/null || true)"

        case "$sb_state" in
            *enabled*|*Enabled*)
                ndm_health_pass "Secure Boot enabled"
                ;;
            *disabled*|*Disabled*)
                ndm_health_warn "Secure Boot disabled"
                ;;
            *)
                ndm_health_warn "Unable to determine Secure Boot state"
                ;;
        esac
    else
        ndm_health_warn "mokutil not found"
    fi
}

ndm_health_check_kernel_headers()
{
    local kernel_version=""

    printf '\nInstalled kernels:\n'

    while IFS= read -r kernel_version; do
        if ndm_kernel_headers_installed "$kernel_version"; then
            ndm_health_pass "$kernel_version headers installed"
        else
            ndm_health_warn "$kernel_version headers missing"
        fi
    done < <(ndm_installed_kernels)
}

ndm_health_summary()
{
    printf '\nSummary:\n'
    printf '  Pass: %s\n' "$NDM_HEALTH_PASS_COUNT"
    printf '  Warn: %s\n' "$NDM_HEALTH_WARN_COUNT"
    printf '  Fail: %s\n' "$NDM_HEALTH_FAIL_COUNT"

    if (( NDM_HEALTH_FAIL_COUNT > 0 )); then
        return 1
    fi

    return 0
}
