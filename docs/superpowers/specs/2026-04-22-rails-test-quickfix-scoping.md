# Rails Test Runner — Quickfix Scoping

Extend the existing rails_test feature so single-file test runs don't wipe out
failures from other files in the quickfix list.

## Motivation

Currently `run_nearest`, `run_file`, and `run_all` all call `setqflist(items, 'r')`,
which replaces the entire list. Running one file's tests destroys the
project-wide failure context from a prior `run_all`. The user wants to fix
failures one file at a time while keeping the full list of other failures
visible.

## Behavior

Every rails_test quickfix item is tagged with `module = 'rails_test'` so we
can recognize our own entries on subsequent writes. This also avoids
clobbering unrelated quickfix entries (grep hits, LSP diagnostics, etc.).

Three scoping rules:

- **`run_all`** — scope is `nil`. Drop every item whose `module == 'rails_test'`.
  Keep any non-rails items. Append the new run's items.
- **`run_file`** — scope is `vim.fn.expand('%:p')` (absolute path of current
  buffer). Drop rails_test items whose file resolves to the same absolute
  path. Keep rails_test items from other files and all non-rails items.
  Append the new run's items.
- **`run_nearest`** — same scoping rule as `run_file` (scope is current file's
  absolute path). Running nearest replaces that entire file's failures with
  whatever the new run reports, matching approach A from the brainstorm:
  simple, robust, no Ruby-aware line parsing. If the user wants to verify one
  failure inside a file with multiple known failures, they'll see the whole
  file's updated results — still correct, just not surgical.

## Post-run UX

`copen` vs `notify` is decided by the **new run's item count**, not the merged
list:

- New run has failures → `copen`.
- New run is clean → `✓ tests passed` notification. The quickfix is not
  closed; any remaining items from other files stay visible.

This matches the user's mental model: "did *this* run succeed?" — not "is the
whole project green?"

## Implementation

Single function changes in `lua/rails_test/init.lua`:

- Add module-level constant `MODULE_TAG = 'rails_test'`.
- `handle_result(lines, exit_code, scope)` — new third parameter.
  1. Parse items; fall back to raw stderr dump if exit code is non-zero and
     parse returned nothing (existing behavior).
  2. Tag every new item with `module = MODULE_TAG`.
  3. Walk `vim.fn.getqflist()` and build a `kept` list using the rules above.
     Existing items arrive as `{ bufnr, lnum, text, type, module, ... }`; we
     resolve bufnr → absolute path via `vim.fn.bufname` +
     `vim.fn.fnamemodify(..., ':p')` to compare against `scope`.
  4. `setqflist(kept ++ new_items, 'r')`.
  5. `#new_items > 0` → `copen`. Else → notify.
- `run(tail_args, scope)` — pass `scope` through to `handle_result` via a
  closure over the runner's `on_exit` callback.
- `run_nearest()` / `run_file()` pass `vim.fn.expand('%:p')` as scope.
  `run_all()` passes `nil`.

No other files change. No new unit tests (init.lua is integration glue per
the original spec). Parser is untouched.

## Edge cases

- **Scope path empty.** `expand('%:p')` returns an empty string for an
  unnamed buffer. If scope is `''`, treat it as `nil` (wipe all) to avoid
  accidentally keeping stale items keyed on an empty string. Realistically
  the user won't invoke nearest/file from a scratch buffer, but guard anyway.
- **Existing item without `bufnr`.** Defensive: if `bufname` returns `''`,
  the item's absolute path is `''`, which won't match a real scope path, so
  the item is kept. Fine.
- **Re-invocation during in-flight run.** Unchanged — the runner's
  supersession guard still no-ops the old callback. The new scope is
  captured in the new closure.

## Verification

Manual checklist (no new automated tests):

1. Run `<leader>ta` on a suite with failures in two files A and B. Confirm
   both appear in quickfix.
2. Fix A's failure. Run `<leader>tf` in A. Confirm A's entries are gone,
   B's entries still present, no copen (new run was clean → notify).
3. Reintroduce a failure in A but in a different test than before.
   `<leader>tn` on that test. Confirm quickfix now shows the new A failure
   plus B's original failures.
4. Add an unrelated entry to the quickfix manually (e.g., `:grep` a pattern).
   Run `<leader>ta`. Confirm the grep entries remain in the list.
