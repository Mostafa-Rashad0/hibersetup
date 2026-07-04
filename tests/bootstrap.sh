#!/usr/bin/env bash
set -Eeuo pipefail

bash -n install.sh
bash -n uninstall.sh
for file in lib/*.sh; do
  bash -n "$file"
done
