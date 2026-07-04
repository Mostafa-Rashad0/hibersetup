#!/usr/bin/env bash

hi_configure_grub() {
  hi_info "Configuring GRUB resume parameters"
  [ -r /etc/default/grub ] || hi_die "/etc/default/grub is missing"
  new_params="resume=UUID=$HI_RESUME_UUID resume_offset=$HI_RESUME_OFFSET"
  if [ "$HI_DRY_RUN" -eq 1 ]; then
    hi_info "DRY-RUN: update GRUB_CMDLINE_LINUX_DEFAULT with $new_params"
    return 0
  fi
  python3 - "$new_params" <<'PY'
import re, shlex, sys
from pathlib import Path
path = Path('/etc/default/grub')
new_params = sys.argv[1].split()
text = path.read_text()
pattern = re.compile(r"^(GRUB_CMDLINE_LINUX_DEFAULT=)([\"\'])(.*)(\\2)$", re.M)
match = pattern.search(text)
if not match:
    raise SystemExit('GRUB_CMDLINE_LINUX_DEFAULT not found')
existing = shlex.split(match.group(3))
filtered = [p for p in existing if not (p.startswith('resume=') or p.startswith('resume_offset='))]
value = ' '.join(shlex.quote(p) for p in filtered + new_params)
replacement = f'{match.group(1)}"{value}"'
path.write_text(pattern.sub(replacement, text, count=1))
PY
  hi_success "GRUB defaults updated"
}

hi_update_grub() {
  hi_info "Running update-grub"
  hi_run update-grub
  hi_success "GRUB configuration regenerated"
}
