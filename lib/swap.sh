#!/usr/bin/env bash

HI_RAM_KB=0
HI_SWAP_PATH=/swapfile
HI_SWAP_SIZE_MIB=0
HI_ACTIVE_SWAP_PATH=
HI_ACTIVE_SWAP_TYPE=
HI_ACTIVE_SWAP_SIZE_KB=0

hi_detect_memory_and_swap() {
  hi_info "Detecting RAM and swap"
  HI_RAM_KB=$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)
  [ "$HI_RAM_KB" -gt 0 ] || hi_die "Could not detect system RAM"
  if [ -r /proc/swaps ]; then
    swap_line=$(awk 'NR>1 && $1 ~ /^\// {print; exit}' /proc/swaps)
    if [ -n "$swap_line" ]; then
      HI_ACTIVE_SWAP_PATH=$(printf '%s\n' "$swap_line" | awk '{print $1}')
      HI_ACTIVE_SWAP_TYPE=$(printf '%s\n' "$swap_line" | awk '{print $2}')
      HI_ACTIVE_SWAP_SIZE_KB=$(printf '%s\n' "$swap_line" | awk '{print $3}')
      HI_SWAP_PATH=$HI_ACTIVE_SWAP_PATH
    fi
  fi
  hi_success "Detected RAM: $(( (HI_RAM_KB + 1023) / 1024 )) MiB; swap: ${HI_ACTIVE_SWAP_PATH:-none}"
}

hi_recommended_swap_mib() {
  ram_mib=$(( (HI_RAM_KB + 1023) / 1024 ))
  if [ "$ram_mib" -le 8192 ]; then
    echo 8192
  elif [ "$ram_mib" -le 16384 ]; then
    echo 20480
  elif [ "$ram_mib" -le 32768 ]; then
    echo 40960
  else
    echo $((ram_mib + 4096))
  fi
}

hi_swap_needs_replacement() {
  recommended_kb=$(( $(hi_recommended_swap_mib) * 1024 ))
  if [ -z "$HI_ACTIVE_SWAP_PATH" ]; then return 0; fi
  if [ "$HI_ACTIVE_SWAP_TYPE" != file ]; then
    hi_die "Active swap is not a swapfile. Phase 1 supports swapfile only."
  fi
  [ "$HI_ACTIVE_SWAP_SIZE_KB" -lt "$recommended_kb" ]
}

hi_create_swapfile_at() {
  path=$1
  mib=$2
  hi_info "Creating swapfile $path (${mib} MiB)"
  if [ "$HI_DRY_RUN" -eq 1 ]; then
    hi_info "DRY-RUN: create and mkswap $path"
    return 0
  fi
  rm -f "$path"
  if hi_command_exists fallocate && fallocate -l "${mib}M" "$path"; then
    :
  else
    dd if=/dev/zero of="$path" bs=1M count="$mib" status=progress
  fi
  chmod 0600 "$path"
  mkswap "$path" >/dev/null
}

hi_create_validated_swap_candidate() {
  tmp_path=$1
  attempt=1
  while :; do
    hi_create_swapfile_at "$tmp_path" "$HI_SWAP_SIZE_MIB"
    if hi_validate_swapfile_extents "$tmp_path"; then
      break
    fi
    if [ "$attempt" -ge 3 ]; then
      hi_die "Swapfile remained fragmented after 3 attempts. Free disk space or defragment the ext4 filesystem, then retry."
    fi
    attempt=$((attempt + 1))
    hi_warning "Recreating swapfile because extent validation failed (attempt $attempt of 3)"
  done
}

hi_activate_replacement_swap() {
  new_path=$1
  tmp_path=$2
  old_path=$3
  backup_path=

  if [ "$HI_DRY_RUN" -eq 1 ]; then
    hi_info "DRY-RUN: activate replacement swap $new_path"
    return 0
  fi

  if [ -e "$new_path" ]; then
    backup_path="${new_path}.hibernate-installer-backup"
    rm -f "$backup_path"
    cp -a "$new_path" "$backup_path"
  fi

  if [ -n "$old_path" ]; then
    if ! swapoff "$old_path"; then
      rm -f "$tmp_path" "$backup_path"
      hi_die "Could not disable existing swapfile $old_path; leaving current swap untouched"
    fi
  fi

  mv "$tmp_path" "$new_path"
  if ! swapon "$new_path"; then
    hi_error "Failed to activate new swapfile; attempting rollback"
    swapoff "$new_path" 2>/dev/null || true
    if [ -n "$backup_path" ] && [ -e "$backup_path" ]; then
      mv "$backup_path" "$new_path"
      swapon "$new_path" || true
    fi
    hi_die "New swapfile activation failed; rollback attempted"
  fi

  rm -f "$backup_path"
}

hi_ensure_swap() {
  HI_SWAP_SIZE_MIB=$(hi_recommended_swap_mib)
  if ! hi_swap_needs_replacement; then
    hi_success "Existing swapfile is large enough"
  else
    new_path=$HI_SWAP_PATH
    tmp_path="${new_path}.hibernate-installer-new"
    hi_create_validated_swap_candidate "$tmp_path"
    hi_activate_replacement_swap "$new_path" "$tmp_path" "$HI_ACTIVE_SWAP_PATH"
    HI_SWAP_PATH=$new_path
    hi_success "Swapfile ready at $HI_SWAP_PATH"
  fi
  hi_persist_swap
}

hi_persist_swap() {
  if [ "$HI_DRY_RUN" -eq 1 ]; then
    hi_info "DRY-RUN: persist swap in /etc/fstab"
    return 0
  fi
  tmp=$(mktemp)
  awk -v path="$HI_SWAP_PATH" 'BEGIN{written=0} $1==path && $3=="swap" {$0=path" none swap sw 0 0"; written=1} {print} END{if(!written) print path" none swap sw 0 0"}' /etc/fstab > "$tmp"
  install -m 0644 "$tmp" /etc/fstab
  rm -f "$tmp"
  hi_success "Swap persisted in /etc/fstab"
}

hi_validate_swapfile_extents() {
  path=$1
  hi_command_exists filefrag || hi_die "filefrag is required to validate swapfile extents"
  if [ "$HI_DRY_RUN" -eq 1 ]; then return 0; fi
  extents=$(filefrag -v "$path" | awk '/^[[:space:]]*[0-9]+:/ {count++} END{print count+0}')
  if [ "$extents" -le 1 ]; then
    hi_success "Swapfile extent validation passed"
    return 0
  fi
  hi_warning "Swapfile $path has $extents extents; hibernation resume needs one extent on ext4"
  return 1
}
