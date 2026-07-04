#!/usr/bin/env bash

HI_ROOT_DEVICE=
HI_ROOT_SOURCE=
HI_ROOT_FSTYPE=
HI_ROOT_UUID=

hi_detect_filesystem() {
  hi_info "Detecting root filesystem"
  hi_command_exists findmnt || hi_die "findmnt is required"
  HI_ROOT_SOURCE=$(findmnt -no SOURCE /)
  HI_ROOT_FSTYPE=$(findmnt -no FSTYPE /)
  HI_ROOT_DEVICE=$(findmnt -no SOURCE -T /)
  case "$HI_ROOT_FSTYPE" in
    ext4) ;;
    btrfs|xfs|zfs) hi_die "$HI_ROOT_FSTYPE is not supported in Phase 1 because resume_offset handling differs. Supported filesystem: ext4." ;;
    *) hi_die "Unsupported root filesystem: $HI_ROOT_FSTYPE. Supported filesystem: ext4." ;;
  esac
  HI_ROOT_UUID=$(findmnt -no UUID /)
  if [ -z "$HI_ROOT_UUID" ]; then
    HI_ROOT_UUID=$(blkid -s UUID -o value "$HI_ROOT_SOURCE" 2>/dev/null || true)
  fi
  if [ -z "$HI_ROOT_UUID" ] && hi_command_exists lsblk; then
    HI_ROOT_UUID=$(lsblk -no UUID "$HI_ROOT_SOURCE" 2>/dev/null | head -n 1 || true)
  fi
  if [ -z "$HI_ROOT_UUID" ] && [ "$HI_DRY_RUN" -eq 1 ]; then
    HI_ROOT_UUID=00000000-0000-0000-0000-000000000000
    hi_warning "Using placeholder UUID because dry-run environment does not expose a filesystem UUID"
  fi
  [ -n "$HI_ROOT_UUID" ] || hi_die "Could not detect filesystem UUID for /"
  hi_success "Detected ext4 root filesystem UUID: $HI_ROOT_UUID"
}
