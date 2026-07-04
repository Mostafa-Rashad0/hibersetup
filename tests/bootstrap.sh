#!/usr/bin/env bash
set -Eeuo pipefail

bash -n install.sh
bash -n uninstall.sh
for file in lib/*.sh; do
  bash -n "$file"
done
python3 -m py_compile /dev/stdin <<'PY'
print('python available')
PY
