#!/usr/bin/env bash

HI_VERIFY_FAILED=0

hi_verify_item() {
  name=$1
  shift
  if "$@"; then
    hi_success "PASS $name"
  else
    HI_VERIFY_FAILED=1
    hi_error "FAIL $name"
  fi
}

hi_verify_swap_active() { swapon --show=NAME --noheadings | grep -Fx -- "$HI_SWAP_PATH" >/dev/null 2>&1; }
hi_verify_resume_conf() { grep -Fx -- "RESUME=UUID=$HI_RESUME_UUID resume_offset=$HI_RESUME_OFFSET" /etc/initramfs-tools/conf.d/resume >/dev/null 2>&1; }
hi_verify_grub_defaults() { grep -q "resume=UUID=$HI_RESUME_UUID" /etc/default/grub && grep -q "resume_offset=$HI_RESUME_OFFSET" /etc/default/grub; }
hi_verify_fstab() { awk -v path="$HI_SWAP_PATH" '$1==path && $3=="swap" {found=1} END{exit found?0:1}' /etc/fstab; }
hi_verify_offset() { [ -n "$HI_RESUME_OFFSET" ]; }

hi_run_verification() {
  hi_info "Running verification checks"
  if [ "$HI_DRY_RUN" -eq 1 ]; then
    hi_warning "Verification skipped in dry-run mode"
    return 0
  fi
  HI_VERIFY_FAILED=0
  hi_verify_item "Swap active" hi_verify_swap_active
  hi_verify_item "fstab swap entry" hi_verify_fstab
  hi_verify_item "Resume offset detected" hi_verify_offset
  hi_verify_item "GRUB resume parameters" hi_verify_grub_defaults
  hi_verify_item "initramfs resume config" hi_verify_resume_conf
  [ "$HI_VERIFY_FAILED" -eq 0 ] || hi_die "One or more verification checks failed"
  hi_success "All verification checks passed"
}
