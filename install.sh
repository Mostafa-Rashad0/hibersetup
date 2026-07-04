#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=lib/logger.sh
. "$SCRIPT_DIR/lib/logger.sh"
# shellcheck source=lib/utils.sh
. "$SCRIPT_DIR/lib/utils.sh"
# shellcheck source=lib/checks.sh
. "$SCRIPT_DIR/lib/checks.sh"
# shellcheck source=lib/filesystem.sh
. "$SCRIPT_DIR/lib/filesystem.sh"
# shellcheck source=lib/swap.sh
. "$SCRIPT_DIR/lib/swap.sh"
# shellcheck source=lib/resume.sh
. "$SCRIPT_DIR/lib/resume.sh"
# shellcheck source=lib/grub.sh
. "$SCRIPT_DIR/lib/grub.sh"
# shellcheck source=lib/initramfs.sh
. "$SCRIPT_DIR/lib/initramfs.sh"
# shellcheck source=lib/secureboot.sh
. "$SCRIPT_DIR/lib/secureboot.sh"
# shellcheck source=lib/gnome.sh
. "$SCRIPT_DIR/lib/gnome.sh"
# shellcheck source=lib/polkit.sh
. "$SCRIPT_DIR/lib/polkit.sh"
# shellcheck source=lib/verify.sh
. "$SCRIPT_DIR/lib/verify.sh"

main() {
  hi_parse_common_args "$@"
  hi_init_logger
  hi_info "Hibernate Installer v1.0.0 started"
  hi_require_root
  hi_detect_os
  hi_detect_filesystem
  hi_detect_memory_and_swap
  hi_detect_secure_boot
  hi_detect_boot_stack
  hi_prepare_backups
  hi_ensure_swap
  hi_detect_resume
  hi_configure_grub
  hi_configure_initramfs_resume
  hi_configure_gnome
  hi_configure_polkit
  hi_update_grub
  hi_update_initramfs
  hi_run_verification
  hi_success "Hibernate configuration completed"
  if hi_confirm "Reboot now to test hibernation?"; then
    hi_run reboot
  else
    hi_warning "Reboot later before testing hibernation."
  fi
}

main "$@"
