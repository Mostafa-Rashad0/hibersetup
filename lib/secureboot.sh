#!/usr/bin/env bash

HI_SECURE_BOOT=unknown

hi_detect_secure_boot() {
  hi_info "Detecting Secure Boot"
  if hi_command_exists mokutil; then
    if mokutil --sb-state 2>/dev/null | grep -qi enabled; then
      HI_SECURE_BOOT=enabled
      hi_warning "Secure Boot is enabled. Phase 1 does not change Secure Boot policy."
    else
      HI_SECURE_BOOT=disabled
    fi
  else
    HI_SECURE_BOOT=unknown
    hi_warning "mokutil not found; Secure Boot state is unknown"
  fi
}
