#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=lib/logger.sh
. "$SCRIPT_DIR/lib/logger.sh"
# shellcheck source=lib/utils.sh
. "$SCRIPT_DIR/lib/utils.sh"
# shellcheck source=lib/checks.sh
. "$SCRIPT_DIR/lib/checks.sh"

latest_backup_dir() {
  if [ ! -d /var/backups/hibernate-installer ]; then
    return 1
  fi
  find /var/backups/hibernate-installer -mindepth 1 -maxdepth 1 -type d | sort | tail -n 1
}

restore_from_latest_backup() {
  backup_dir=$(latest_backup_dir || true)
  if [ -z "$backup_dir" ]; then
    hi_warning "No previous Hibernate Installer backup found; removing managed settings directly"
    return 1
  fi
  hi_info "Restoring configuration from $backup_dir"
  for path in /etc/default/grub /etc/fstab /etc/initramfs-tools/conf.d/resume; do
    src="$backup_dir$path"
    if [ -e "$src" ]; then
      if [ "$HI_DRY_RUN" -eq 1 ]; then
        hi_info "DRY-RUN: restore $path from $src"
      else
        mkdir -p "$(dirname "$path")"
        cp -a "$src" "$path"
      fi
    fi
  done
  return 0
}

remove_resume_params_from_grub() {
  [ -r /etc/default/grub ] || return 0
  if [ "$HI_DRY_RUN" -eq 1 ]; then
    hi_info "DRY-RUN: remove resume parameters from /etc/default/grub"
    return 0
  fi
  python3 - <<'PY'
import re, shlex
from pathlib import Path
path = Path('/etc/default/grub')
text = path.read_text()
pattern = re.compile(r"^(GRUB_CMDLINE_LINUX_DEFAULT=)([\"\'])(.*)(\2)$", re.M)
match = pattern.search(text)
if not match:
    raise SystemExit(0)
existing = shlex.split(match.group(3))
filtered = [p for p in existing if not (p.startswith('resume=') or p.startswith('resume_offset='))]
value = ' '.join(shlex.quote(p) for p in filtered)
path.write_text(pattern.sub(f'{match.group(1)}"{value}"', text, count=1))
PY
}

remove_generated_files() {
  for path in \
    /etc/initramfs-tools/conf.d/resume \
    /etc/systemd/sleep.conf.d/hibernate-installer.conf \
    /etc/polkit-1/rules.d/49-hibernate-installer.rules
  do
    if [ -e "$path" ]; then
      if [ "$HI_DRY_RUN" -eq 1 ]; then
        hi_info "DRY-RUN: remove $path"
      else
        rm -f "$path"
      fi
    fi
  done
}

main() {
  hi_parse_common_args "$@"
  hi_init_logger
  hi_info "Hibernate Installer uninstall started"
  hi_require_root
  hi_prepare_backups
  if ! restore_from_latest_backup; then
    remove_resume_params_from_grub
  fi
  remove_generated_files
  if hi_command_exists update-grub; then hi_run update-grub; fi
  if hi_command_exists update-initramfs; then hi_run update-initramfs -u; fi
  hi_success "Hibernate Installer managed configuration removed"
}

main "$@"
