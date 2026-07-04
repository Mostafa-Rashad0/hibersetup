#!/usr/bin/env bash

hi_die() {
  hi_error "$1"
  exit 1
}

hi_command_exists() {
  command -v "$1" >/dev/null 2>&1
}
