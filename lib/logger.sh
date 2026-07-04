#!/usr/bin/env bash

HI_LOG_FILE=${HI_LOG_FILE:-/var/log/hibernate-installer.log}
HI_COLOR_INFO='\033[34m'
HI_COLOR_SUCCESS='\033[32m'
HI_COLOR_WARNING='\033[33m'
HI_COLOR_ERROR='\033[31m'
HI_LOG_ENABLED=0
HI_COLOR_RESET='\033[0m'

hi_init_logger() {
  if [ "$(id -u)" -eq 0 ]; then
    touch "$HI_LOG_FILE"
    chmod 0644 "$HI_LOG_FILE"
    HI_LOG_ENABLED=1
  else
    HI_LOG_ENABLED=0
  fi
}

hi_log() {
  level=$1
  message=$2

  if [ "$HI_LOG_ENABLED" -ne 1 ]; then
    return 0
  fi

  timestamp=$(date '+%Y-%m-%dT%H:%M:%S%z')
  printf '%s %s %s\n' "$timestamp" "$level" "$message" >> "$HI_LOG_FILE"
}

hi_print() {
  color=$1
  level=$2
  message=$3
  printf '%b%s%b %s\n' "$color" "$level" "$HI_COLOR_RESET" "$message"
  hi_log "$level" "$message"
}

hi_info() { hi_print "$HI_COLOR_INFO" INFO "$1"; }
hi_success() { hi_print "$HI_COLOR_SUCCESS" SUCCESS "$1"; }
hi_warning() { hi_print "$HI_COLOR_WARNING" WARNING "$1"; }
hi_error() { hi_print "$HI_COLOR_ERROR" ERROR "$1"; }
