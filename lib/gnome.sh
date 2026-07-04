#!/usr/bin/env bash

hi_configure_gnome() {
  hi_info "Configuring GNOME hibernate visibility"
  if [ -d /etc/systemd ]; then
    hi_run mkdir -p /etc/systemd/sleep.conf.d
    hi_write_file /etc/systemd/sleep.conf.d/hibernate-installer.conf '[Sleep]
AllowHibernation=yes
AllowSuspendThenHibernate=yes'
  fi
  hi_success "GNOME/systemd hibernate policy prepared"
}
