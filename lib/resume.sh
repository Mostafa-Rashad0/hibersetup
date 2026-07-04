#!/usr/bin/env bash

HI_RESUME_UUID=
HI_RESUME_OFFSET=
HI_RESUME_SERVICE=/etc/systemd/system/hibernate-installer-resume.service
HI_RESUME_HELPER=/usr/local/lib/hibernate-installer/set-resume.sh

hi_detect_resume() {
  hi_info "Detecting hibernation resume target"
  [ -n "$HI_SWAP_PATH" ] || hi_die "Swap path is unknown"
  HI_RESUME_UUID=$HI_ROOT_UUID
  HI_RESUME_OFFSET=$(hi_get_resume_offset "$HI_SWAP_PATH")
  [ -n "$HI_RESUME_OFFSET" ] || hi_die "Resume offset not found for $HI_SWAP_PATH"
  hi_success "Detected resume=UUID=$HI_RESUME_UUID resume_offset=$HI_RESUME_OFFSET"
}

hi_get_resume_offset() {
  path=$1
  hi_command_exists filefrag || hi_die "filefrag is required to calculate resume_offset"
  if [ "$HI_DRY_RUN" -eq 1 ]; then
    echo 0
    return 0
  fi
  filefrag -v "$path" | awk '/^[[:space:]]*0:/ {gsub(/\./, "", $4); print $4; exit}'
}

hi_configure_resume_sysfs_service() {
  hi_info "Configuring systemd resume sysfs service"
  if [ "$HI_DRY_RUN" -eq 1 ]; then
    hi_info "DRY-RUN: install resume sysfs helper and service"
    return 0
  fi
  install -d -m 0755 /usr/local/lib/hibernate-installer
  cat > "$HI_RESUME_HELPER" <<EOF_HELPER
#!/usr/bin/env bash
set -Eeuo pipefail
resume_uuid='$HI_RESUME_UUID'
resume_offset='$HI_RESUME_OFFSET'
resume_device=\$(findfs "UUID=\$resume_uuid")
maj_min=\$(lsblk -no MAJ:MIN "\$resume_device" | head -n 1 | tr -d ' ')
[ -n "\$maj_min" ]
printf '%s\n' "\$maj_min" > /sys/power/resume
if [ -w /sys/power/resume_offset ]; then
  printf '%s\n' "\$resume_offset" > /sys/power/resume_offset
fi
EOF_HELPER
  chmod 0755 "$HI_RESUME_HELPER"
  cat > "$HI_RESUME_SERVICE" <<EOF_SERVICE
[Unit]
Description=Populate kernel hibernate resume sysfs values
DefaultDependencies=no
After=local-fs.target
Before=sleep.target

[Service]
Type=oneshot
ExecStart=$HI_RESUME_HELPER
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF_SERVICE
  systemctl daemon-reload
  systemctl enable --now hibernate-installer-resume.service
  hi_success "Resume sysfs service installed and started"
}
