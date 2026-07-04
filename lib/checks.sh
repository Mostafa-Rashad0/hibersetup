#!/usr/bin/env bash

hi_require_root() {
  if [ "$(id -u)" -ne 0 ]; then
    hi_die "This installer must be run as root. Use: sudo ./install.sh"
  fi
  hi_success "Root privileges verified"
}

hi_detect_os() {
  if [ ! -r /etc/os-release ]; then
    hi_die "Cannot detect operating system because /etc/os-release is missing"
  fi

  # shellcheck disable=SC1091
  . /etc/os-release
  if [ "${ID:-}" != "ubuntu" ]; then
    hi_die "Unsupported operating system: ${PRETTY_NAME:-unknown}. Supported: Ubuntu 24.04 LTS and 26.04 LTS."
  fi

  case "${VERSION_ID:-}" in
    24.04|26.04)
      hi_success "Supported Ubuntu release detected: ${VERSION_ID}"
      ;;
    *)
      hi_die "Unsupported Ubuntu release: ${VERSION_ID:-unknown}. Supported: 24.04 LTS and 26.04 LTS."
      ;;
  esac
}
