#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
# Both starts share this one isolated environment; every invocation installs afresh.
# shellcheck disable=SC2016
"$repo_root/tests/with-isolated-xdg.sh" bash -c '
  set -euo pipefail
  rm -rf -- "$XDG_DATA_HOME/nvim" "$XDG_STATE_HOME/nvim" "$XDG_CACHE_HOME/nvim"
  test ! -e "$XDG_DATA_HOME/nvim"
  test ! -e "$XDG_STATE_HOME/nvim"
  test ! -e "$XDG_CACHE_HOME/nvim"
  printf "%s\n" "PRISTINE: no Neovim data, state, cache, or installed plugins"
  status=0
  for phase in first second; do
    phase_status=0
    NVIM_THEME_PHASE="$phase" timeout 900 nvim --headless \
      --cmd "lua dofile(\"tests/bootstrap.lua\"); dofile(\"tests/theme-startup.lua\")" \
      || phase_status=$?
    printf "\nTHEME_STARTUP %s exit=%s\n" "$phase" "$phase_status"
    if [ "$phase_status" -ne 0 ]; then status=1; fi
  done
  exit "$status"
'
