#!/usr/bin/env bash

HI_POLKIT_RULE=/etc/polkit-1/rules.d/49-hibernate-installer.rules

hi_configure_polkit() {
  hi_info "Configuring polkit hibernate permission"
  hi_run mkdir -p /etc/polkit-1/rules.d
  hi_write_file "$HI_POLKIT_RULE" 'polkit.addRule(function(action, subject) {
  if ((action.id == "org.freedesktop.login1.hibernate" ||
       action.id == "org.freedesktop.login1.hibernate-multiple-sessions") &&
      subject.active == true && subject.local == true) {
    return polkit.Result.YES;
  }
});'
  hi_success "Polkit hibernate rule installed"
}
