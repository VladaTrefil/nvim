#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
"$repo_root/tests/with-isolated-xdg.sh" bash -c '
  set -euo pipefail
  nvim --headless --cmd "lua dofile(\"tests/bootstrap.lua\")" \
    -c "lua if vim.v.errmsg ~= \"\" then print(vim.v.errmsg); vim.cmd(\"cquit 1\") end" \
    -c "PlenaryBustedFile lua/rails_test/parser_spec.lua" -c "qa!"
  if command -v selene >/dev/null 2>&1; then
    selene lua
  else
    printf "%s\n" "SKIP: selene is not on PATH; Lua lint was not run."
  fi
'
