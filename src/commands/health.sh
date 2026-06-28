#!/usr/bin/env bash
# shellcheck shell=bash

# shellcheck disable=SC1091
source "$NDM_LIB_DIR/system.sh"
# shellcheck disable=SC1091
source "$NDM_LIB_DIR/version.sh"

PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0

health_pass()
{
    printf '✓ %s\n' "$1"
    PASS_COUNT=$((PASS_COUNT + 1))
}

health_warn()
{
    printf '! %s\n' "$1"
    WARN_COUNT=$((WARN_COUNT + 1))
}

health_fail()
{
    printf '✗ %s\n' "$1"
    FAIL_COUNT=$((FAIL_COUNT + 1))
}

printf 'NVIDIA Driver Manager Health Report\n\n'

if ndm_command_exists nvidia-smi; then
    health_pass "nvidia-smi found"
else
    health_fail "nvidia-smi not found"
fi

if INSTALLED_VERSION="$(ndm_get_installed_version)"; then
    health_pass "NVIDIA driver detected: $INSTALLED_VERSION"
else
    health_fail "Unable to detect NVIDIA driver version"
fi

if DKMS_BIN="$(ndm_command_path dkms)"; then
    health_pass "DKMS found: $DKMS_BIN"

    DKMS_STATUS="$("$DKMS_BIN" status 2>/dev/null || true)"

    if printf '%s\n' "$DKMS_STATUS" | grep -qi 'nvidia'; then
        health_pass "NVIDIA module registered with DKMS"
    else
        health_warn "DKMS found, but NVIDIA module is not registered"
        if [[ -n "$DKMS_STATUS" ]]; then
            printf '%s\n' "$DKMS_STATUS"
        fi
    fi
else
    health_fail "DKMS not found"
fi

if ndm_command_exists curl; then
    health_pass "curl found"
else
    health_fail "curl not found"
fi

if ndm_command_exists xmllint; then
    health_pass "xmllint found"
else
    health_fail "xmllint not found; install libxml2-utils"
fi

if ndm_command_exists zenity; then
    health_pass "Zenity found"
else
    health_warn "Zenity not found"
fi

if ndm_command_exists pkexec; then
    health_pass "pkexec found"
else
    health_warn "pkexec not found"
fi

if ndm_command_exists mokutil; then
    MOKUTIL_BIN="$(ndm_command_path mokutil)"
    SB_STATE="$("$MOKUTIL_BIN" --sb-state 2>/dev/null || true)"

    case "$SB_STATE" in
        *enabled*|*Enabled*)
            health_pass "Secure Boot enabled"
            ;;
        *disabled*|*Disabled*)
            health_warn "Secure Boot disabled"
            ;;
        *)
            health_warn "Unable to determine Secure Boot state"
            ;;
    esac
else
    health_warn "mokutil not found"
fi

printf '\nInstalled kernels:\n'

while IFS= read -r kernel_version; do
    if ndm_kernel_headers_installed "$kernel_version"; then
        printf '✓ %s headers installed\n' "$kernel_version"
        PASS_COUNT=$((PASS_COUNT + 1))
    else
        printf '! %s headers missing\n' "$kernel_version"
        WARN_COUNT=$((WARN_COUNT + 1))
    fi
done < <(ndm_installed_kernels)

printf '\nSummary:\n'
printf '  Pass: %s\n' "$PASS_COUNT"
printf '  Warn: %s\n' "$WARN_COUNT"
printf '  Fail: %s\n' "$FAIL_COUNT"

if (( FAIL_COUNT > 0 )); then
    exit 1
fi

exit 0
