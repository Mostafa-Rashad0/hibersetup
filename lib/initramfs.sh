#!/usr/bin/env bash

HI_RESUME_CONF=/etc/initramfs-tools/conf.d/resume

hi_configure_initramfs_resume() {
  hi_info "Writing initramfs resume configuration"
  content="RESUME=UUID=$HI_RESUME_UUID resume_offset=$HI_RESUME_OFFSET"
  hi_write_file "$HI_RESUME_CONF" "$content"
  hi_success "initramfs resume configuration ready"
}

hi_update_initramfs() {
  hi_info "Running update-initramfs -u"
  hi_run update-initramfs -u
  hi_success "initramfs updated"
}
