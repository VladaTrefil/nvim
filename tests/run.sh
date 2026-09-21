#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
# Variables in this script body expand inside the isolated shell.
# shellcheck disable=SC2016
"$repo_root/tests/with-isolated-xdg.sh" bash -c '
  set -euo pipefail
  spec_status=0
  nvim --headless --cmd "lua dofile(\"tests/bootstrap.lua\")" \
    -c "lua if vim.v.errmsg ~= \"\" then print(vim.v.errmsg); vim.cmd(\"cquit 1\") end" \
    -c "PlenaryBustedFile lua/rails_test/parser_spec.lua" -c "qa!" || spec_status=$?
  printf "Specs exit status: %s\n" "$spec_status"
  if command -v selene >/dev/null 2>&1; then
    lint_status=0
    selene lua || lint_status=$?
    printf "Lua lint exit status: %s (non-fatal; deferred lint debt).\n" "$lint_status"
  else
    printf "%s\n" "SKIP: selene is not on PATH; Lua lint was not run."
  fi
  exit "$spec_status"
'
