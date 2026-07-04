#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=lib/logger.sh
. "$SCRIPT_DIR/lib/logger.sh"
# shellcheck source=lib/utils.sh
. "$SCRIPT_DIR/lib/utils.sh"
# shellcheck source=lib/checks.sh
. "$SCRIPT_DIR/lib/checks.sh"

main() {
  hi_init_logger
  hi_info "Hibernate Installer v1.0.0 bootstrap started"
  hi_require_root
  hi_detect_os
  hi_success "Initial project bootstrap checks completed"
  hi_info "Further configuration modules will run in the next approved milestone."
}

main "$@"
