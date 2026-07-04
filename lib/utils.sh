#!/usr/bin/env bash

HI_DRY_RUN=${HI_DRY_RUN:-0}
HI_VERBOSE=${HI_VERBOSE:-0}
HI_DEBUG=${HI_DEBUG:-0}
HI_ASSUME_YES=${HI_ASSUME_YES:-0}
HI_BACKUP_DIR=${HI_BACKUP_DIR:-}

hi_die() {
  hi_error "$1"
  exit 1
}

hi_command_exists() {
  command -v "$1" >/dev/null 2>&1
}

hi_run() {
  if [ "$HI_DRY_RUN" -eq 1 ]; then
    hi_info "DRY-RUN: $*"
    return 0
  fi
  if [ "$HI_DEBUG" -eq 1 ]; then
    set -x
  fi
  set +e
  "$@"
  status=$?
  set -e
  if [ "$HI_DEBUG" -eq 1 ]; then
    set +x
  fi
  return "$status"
}

hi_write_file() {
  path=$1
  content=$2
  if [ "$HI_DRY_RUN" -eq 1 ]; then
    hi_info "DRY-RUN: write $path"
    return 0
  fi
  printf '%s\n' "$content" > "$path"
}

hi_append_line_if_missing() {
  path=$1
  line=$2
  if [ -f "$path" ] && grep -Fx -- "$line" "$path" >/dev/null 2>&1; then
    return 0
  fi
  if [ "$HI_DRY_RUN" -eq 1 ]; then
    hi_info "DRY-RUN: append to $path: $line"
    return 0
  fi
  printf '%s\n' "$line" >> "$path"
}

hi_backup_path() {
  path=$1
  [ -n "$HI_BACKUP_DIR" ] || hi_die "Backup directory has not been initialized"
  if [ ! -e "$path" ]; then
    hi_warning "Skipping backup for missing path: $path"
    return 0
  fi
  mkdir -p "$HI_BACKUP_DIR"
  target="$HI_BACKUP_DIR${path}"
  mkdir -p "$(dirname "$target")"
  cp -a "$path" "$target"
  hi_success "Backed up $path to $target"
}

hi_parse_common_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --dry-run) HI_DRY_RUN=1 ;;
      --verbose|-v) HI_VERBOSE=1 ;;
      --debug) HI_DEBUG=1 ;;
      --yes|-y) HI_ASSUME_YES=1 ;;
      --help|-h)
        cat <<'HELP'
Usage: sudo ./install.sh [--dry-run] [--verbose] [--debug] [--yes]

Options:
  --dry-run   Print intended actions without changing the system.
  --verbose   Enable extra progress output.
  --debug     Enable shell tracing while running commands.
  --yes       Do not prompt before reboot offer.
HELP
        exit 0
        ;;
      *) hi_die "Unknown option: $1" ;;
    esac
    shift
  done
}

hi_confirm() {
  prompt=$1
  if [ "$HI_ASSUME_YES" -eq 1 ]; then
    return 0
  fi
  printf '%s [y/N]: ' "$prompt"
  read -r answer || return 1
  case "$answer" in
    y|Y|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}
