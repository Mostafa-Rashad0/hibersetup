#!/usr/bin/env bash

HI_RESUME_UUID=
HI_RESUME_OFFSET=

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
