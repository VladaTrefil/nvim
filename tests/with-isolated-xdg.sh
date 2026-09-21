#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
test_root=$(mktemp -d "${TMPDIR:-/tmp}/nvim-next-tests.XXXXXXXX")
trap 'rm -rf -- "$test_root"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

mkdir -p "$test_root"/{home,config,data,state,cache,runtime,tmp,config-dirs,data-dirs}
chmod 700 "$test_root/runtime"
ln -s "$repo_root" "$test_root/config/nvim"
printf 'Isolated Neovim environment: %s\n' "$test_root"

cd -- "$repo_root"
env -i \
  HOME="$test_root/home" \
  TMPDIR="$test_root/tmp" \
  PATH="$PATH" \
  TERM=dumb \
  LANG=C.UTF-8 \
  PYTHONDONTWRITEBYTECODE=1 \
  XDG_CONFIG_HOME="$test_root/config" \
  XDG_DATA_HOME="$test_root/data" \
  XDG_STATE_HOME="$test_root/state" \
  XDG_CACHE_HOME="$test_root/cache" \
  XDG_RUNTIME_DIR="$test_root/runtime" \
  XDG_CONFIG_DIRS="$test_root/config-dirs" \
  XDG_DATA_DIRS="$test_root/data-dirs" \
  "$@"
