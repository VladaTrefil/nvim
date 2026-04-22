# Rails Test Runner — Design

A small, self-contained Neovim feature for running Rails minitest tests and
surfacing failures in the quickfix list. Implemented with native Neovim
primitives only (`jobstart`, `setqflist`) — no plugin dependencies.

## Goals

- Run the test under the cursor, the current test file, or the whole project.
- Execute tests asynchronously so the editor stays usable.
- Parse minitest output into structured quickfix entries with jump-to-file on
  `<CR>` and navigation through the stack trace via `]q`/`[q`.
- Indicate a running test on the statusline.
- Keep the existing `<leader>t*` muscle memory from the prior neotest setup.

## Non-goals

- No live output pane. Output is collected and parsed on job exit only.
- No framework autodetection. Minitest only; RSpec is out of scope.
- No test file browsing UI / summary pane.
- No reruns, watch mode, or coverage integration.

## Architecture

A single self-contained Lua module at `lua/rails_test/`, sitting at the same
level as `lua/core/` and `lua/lsp/`. Three Neovim primitives do all the work:

- `vim.fn.jobstart` — spawn `bin/rails test ...` asynchronously, collect
  stdout/stderr line-by-line.
- `vim.fn.setqflist` — populate the quickfix list directly from parsed output,
  bypassing `errorformat` (minitest's multi-line failures are awkward to
  express as an errorformat pattern).
- Module-level state `M.running` — a lualine component reads this on each
  redraw to render the running indicator.

### User surface

Commands:

- `:RailsTestNearest` — run the test at the cursor line.
- `:RailsTestFile` — run all tests in the current buffer.
- `:RailsTestAll` — run the whole suite in `getcwd()`.

Mappings (mirroring the existing neotest layout):

- `<leader>tn` → nearest
- `<leader>tf` → file
- `<leader>ta` → all

On job completion:

- Failures present → `:copen` is called automatically.
- No failures → `vim.notify('✓ tests passed')`; quickfix is cleared.

## File layout

```
lua/rails_test/
├── init.lua       -- public API: run_nearest(), run_file(), run_all(), is_running()
├── runner.lua     -- jobstart wrapper; owns the "running" state flag
├── parser.lua     -- pure: minitest output → list of quickfix items
└── commands.lua   -- :RailsTest* user_command and <leader>t* keymap registration
```

Plus one edit outside the module:

- `lua/plugins/config/_lualine/init.lua` — add a component to
  `sections.lualine_x` that renders `󰙨 running` when
  `require('rails_test').is_running()` returns `true`.

### Separation of concerns

- `runner.lua` knows nothing about minitest output. It runs a command and
  hands raw stdout/stderr lines to its caller.
- `parser.lua` is pure: `parse(lines) -> { { filename, lnum, text, type }, ... }`.
  No side effects; easy to unit-test.
- `init.lua` wires them together: build the argv, invoke the runner, feed
  collected output through the parser, call `setqflist`.
- `commands.lua` is pure registration — `nvim_create_user_command` +
  `vim.keymap.set` calls, no logic.

This split keeps the parser — the piece most likely to need tweaks as edge
cases surface — isolated and testable without a full Rails app on hand.

## Data flow

Happy path, starting from `<leader>tn` on line 42 of
`test/models/user_test.rb`:

1. `init.run_nearest()` builds `argv = { 'bin/rails', 'test', 'test/models/user_test.rb:42' }`
   with `cwd = vim.fn.getcwd()`.
2. `runner.start(argv)` sets `M.running = true`, calls `jobstart` with
   `on_stdout`, `on_stderr`, `on_exit` callbacks, and triggers
   `vim.cmd('redrawstatus')` so the lualine indicator appears immediately.
3. Stdout lines are appended to an internal `lines[]` buffer. No live
   streaming — the output pane was explicitly rejected.
4. On `on_exit`:
   - `parser.parse(lines)` → list of quickfix items.
   - `vim.fn.setqflist(items, 'r')` (replace).
   - `M.running = false`; `vim.cmd('redrawstatus')`.
   - If `#items > 0`, run `:copen`. Otherwise `vim.notify('✓ tests passed')`.

## Minitest output parsing

Minitest prints two failure shapes we need to handle.

### Failure (assertion failed)

```
Failure:
UserTest#test_should_save [test/models/user_test.rb:15]:
Expected true to be nil or false.

```

The bracketed `[file:line]` on the header line points at the failing
assertion. The message can span multiple lines and is terminated by a blank
line.

### Error (exception raised)

```
Error:
UserTest#test_bar:
NoMethodError: undefined method `foo' for nil:NilClass
    app/models/user.rb:42:in `bar'
    test/models/user_test.rb:20:in `block in <class:UserTest>'

```

No bracketed file:line; instead, a backtrace where each line matches
`    <path>:<lnum>:in '<method>'`.

### Parser state machine

Scan lines top-to-bottom. When a line matches `^Failure:$` or `^Error:$`,
collect subsequent lines until a blank line, then emit quickfix items:

- **Primary entry.** One item at the failing location.
  - For failures: `filename`/`lnum` from the `[file:line]` bracket in the
    header line.
  - For errors: `filename`/`lnum` from the first backtrace line whose path
    is relative (minitest prints project files as relative paths and gem
    files as absolute paths, so "not starting with `/`" is a sufficient gem
    filter).
  - `text` = header + message joined with ` | ` so the failure message is
    readable in `:copen`.
  - `type = 'E'`.
- **Trace entries.** For errors, one item per backtrace frame whose file
  exists under `cwd`. `type = 'W'` so trace frames render distinctly from the
  primary failure.

This gives: `<CR>` jumps to the failing assertion, `]q`/`[q` walks the trace,
and the failure message is visible inline in `:copen`.

## Error handling

- **`bin/rails` missing.** Fail fast: `vim.notify` an error, don't start a job.
  Check via `vim.fn.executable('bin/rails') == 1` before invoking runner.
- **Exit code 0, no failures parsed.** Success path — "passed" notify, clear
  quickfix.
- **Exit code ≠ 0 but parser found nothing.** Likely a Ruby syntax error or
  Rails boot failure. Dump the first 20 stderr lines as quickfix items with
  `type = 'E'` so the user can see what went wrong rather than staring at an
  empty list.
- **Re-invocation while a job is in flight.** Call `jobstop` on the previous
  job, then start the new one. Avoids stale results from an abandoned run.
  The previous job's `on_exit` becomes a no-op because the runner tracks the
  current job id and ignores callbacks from superseded jobs.

## Statusline integration

Added to `sections.lualine_x` in `lua/plugins/config/_lualine/init.lua`:

```lua
{
  function()
    local ok, rt = pcall(require, 'rails_test')
    if not ok or not rt.is_running() then return '' end
    return '󰙨 running'
  end,
  color = { fg = '#e5c07b' },
}
```

No timer. Lualine redraws on normal events, and the runner calls
`vim.cmd('redrawstatus')` explicitly on start and finish for immediate
updates. An animated spinner is deliberately deferred as nice-to-have.

## Testing

Only the parser is unit-tested. Everything else is either thin I/O glue or
interactive UX that's easier to verify by hand.

`lua/rails_test/parser_spec.lua` — plenary-busted tests, fixtures as inline
Lua strings. Covers:

1. Plain failure with `[file:line]` bracket header.
2. Error with multi-line backtrace.
3. Multiple failures in one run.
4. Mixed failure + error in one run.
5. All-passing output → returns `{}`.
6. Garbage / unexpected output → returns `{}`, does not raise.

Run via plenary's busted harness (plenary is already listed as a dependency
in `lua/plugins/plugin_list.lua`).

### Manual verification checklist

1. `<leader>tn` on a passing test → notify, empty quickfix.
2. `<leader>tn` on a failing test → quickfix opens, `<CR>` jumps to the
   assertion line.
3. `<leader>ta` on a long suite → statusline shows `󰙨 running` immediately,
   clears on finish.
4. Trigger `<leader>ta` twice quickly → first job is killed, only the second
   run's results land in quickfix.
5. Rename `bin/rails` temporarily → graceful error notify, no job started.

## Open questions

None at design time. If the parser proves brittle against real-world
minitest output, extend `parser_spec.lua` with a failing fixture first, then
fix — keep the parser honest.
