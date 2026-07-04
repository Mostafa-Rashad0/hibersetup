#!/usr/bin/env bash

HI_OS_ID=
HI_OS_VERSION=
HI_BOOT_MODE=unknown
HI_INITRAMFS=unknown

hi_require_root() {
  if [ "$(id -u)" -ne 0 ]; then
    hi_die "This installer must be run as root. Use: sudo ./install.sh"
  fi
  hi_success "Root privileges verified"
}

hi_detect_os() {
  hi_info "Detecting operating system"
  [ -r /etc/os-release ] || hi_die "Cannot detect operating system because /etc/os-release is missing"
  # shellcheck disable=SC1091
  . /etc/os-release
  HI_OS_ID=${ID:-}
  HI_OS_VERSION=${VERSION_ID:-}
  [ "$HI_OS_ID" = ubuntu ] || hi_die "Unsupported operating system: ${PRETTY_NAME:-unknown}. Supported: Ubuntu 24.04 LTS and 26.04 LTS."
  case "$HI_OS_VERSION" in
    24.04|26.04) hi_success "Supported Ubuntu release detected: $HI_OS_VERSION" ;;
    *) hi_die "Unsupported Ubuntu release: ${HI_OS_VERSION:-unknown}. Supported: 24.04 LTS and 26.04 LTS." ;;
  esac
}

hi_detect_boot_stack() {
  hi_info "Detecting boot mode, GRUB, and initramfs implementation"
  if [ -d /sys/firmware/efi ]; then HI_BOOT_MODE=efi; else HI_BOOT_MODE=bios; fi
  hi_command_exists update-grub || hi_die "GRUB update command not found. Phase 1 supports GRUB only."
  if [ -d /etc/initramfs-tools ]; then
    HI_INITRAMFS=initramfs-tools
  else
    hi_die "Unsupported initramfs implementation. Phase 1 supports initramfs-tools."
  fi
  hi_success "Detected boot mode: $HI_BOOT_MODE; initramfs: $HI_INITRAMFS"
}

hi_prepare_backups() {
  timestamp=$(date '+%Y%m%d-%H%M%S')
  HI_BACKUP_DIR="/var/backups/hibernate-installer/$timestamp"
  if [ "$HI_DRY_RUN" -eq 1 ]; then
    hi_info "DRY-RUN: backup directory would be $HI_BACKUP_DIR"
    return 0
  fi
  mkdir -p "$HI_BACKUP_DIR"
  hi_backup_path /etc/default/grub
  hi_backup_path /etc/fstab
  hi_backup_path /etc/initramfs-tools/conf.d/resume
  hi_success "Backups stored in $HI_BACKUP_DIR"
}
