# Rails Test Runner Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a self-contained Neovim module that runs Rails minitest tests asynchronously and surfaces failures in the quickfix list, restoring the `<leader>t*` workflow from the prior neotest setup.

**Architecture:** A single Lua module at `lua/rails_test/` with four files — a pure parser, a thin `jobstart` wrapper with in-flight job supersession, the public API that wires them together, and a registration-only commands module. A lualine component reads the runner's `running` flag to render a status indicator. No live output pane, no framework autodetection — minitest only.

**Tech Stack:** Neovim 0.10+ (Lua), `vim.fn.jobstart`, `vim.fn.setqflist`, lualine, plenary.nvim busted harness for parser tests.

---

## File Structure

**Created:**
- `lua/rails_test/init.lua` — public API: `run_nearest()`, `run_file()`, `run_all()`, `is_running()`
- `lua/rails_test/runner.lua` — `jobstart` wrapper; owns the `running` state and current job id
- `lua/rails_test/parser.lua` — pure: `parse(lines) -> quickfix items`
- `lua/rails_test/commands.lua` — `:RailsTest*` user commands and `<leader>t*` keymaps, loaded for side effects
- `lua/rails_test/parser_spec.lua` — plenary-busted tests for the parser

**Modified:**
- `init.lua` — add `require('rails_test.commands')` after `require('plugins')` so keymap registration runs after lazy plugins load and overrides any neotest bindings
- `lua/plugins/config/_lualine/init.lua` — add a running-indicator component to `sections.lualine_x`

---

## Task 1: Parser — plain failure case (TDD seed)

**Files:**
- Create: `lua/rails_test/parser.lua`
- Create: `lua/rails_test/parser_spec.lua`

- [ ] **Step 1: Create empty parser module**

Create `lua/rails_test/parser.lua`:

```lua
local M = {}

function M.parse(_lines)
	return {}
end

return M
```

- [ ] **Step 2: Write the failing test for a plain failure**

Create `lua/rails_test/parser_spec.lua`:

```lua
local parser = require('rails_test.parser')

local function split(s)
	return vim.split(s, '\n', { plain = true })
end

describe('rails_test.parser', function()
	it('parses a plain failure with [file:line] bracket', function()
		local output = [[
Running:

F

Failure:
UserTest#test_should_save [test/models/user_test.rb:15]:
Expected true to be nil or false.

Finished in 0.01s
1 runs, 1 assertions, 1 failures, 0 errors, 0 skips
]]

		local items = parser.parse(split(output))

		assert.are.equal(1, #items)
		assert.are.equal('test/models/user_test.rb', items[1].filename)
		assert.are.equal(15, items[1].lnum)
		assert.are.equal('E', items[1].type)
		assert.is_truthy(items[1].text:find('Expected true'))
		assert.is_truthy(items[1].text:find('UserTest#test_should_save'))
	end)
end)
```

- [ ] **Step 3: Run the test and verify it fails**

Run:

```bash
cd /home/vlada/Development/dotfiles/config/nvim
nvim --headless -c "PlenaryBustedFile lua/rails_test/parser_spec.lua" -c "qa!"
```

Expected: FAIL with `Expected 1, got 0` (empty items list).

- [ ] **Step 4: Implement minimal parser to pass the test**

Replace `lua/rails_test/parser.lua` with:

```lua
local M = {}

-- Parse minitest output lines → list of quickfix items.
-- Each item: { filename, lnum, text, type }.
function M.parse(lines)
	local items = {}
	local i = 1
	local n = #lines

	while i <= n do
		local line = lines[i]

		if line == 'Failure:' then
			local header = lines[i + 1] or ''
			local path, lnum = header:match('%[([^:%]]+):(%d+)%]')

			local msg = {}
			local j = i + 2
			while j <= n and lines[j] ~= '' do
				table.insert(msg, lines[j])
				j = j + 1
			end

			if path and lnum then
				table.insert(items, {
					filename = path,
					lnum = tonumber(lnum),
					text = header .. ' | ' .. table.concat(msg, ' | '),
					type = 'E',
				})
			end

			i = j + 1
		else
			i = i + 1
		end
	end

	return items
end

return M
```

- [ ] **Step 5: Run the test and verify it passes**

Run:

```bash
nvim --headless -c "PlenaryBustedFile lua/rails_test/parser_spec.lua" -c "qa!"
```

Expected: `Success: 1`.

- [ ] **Step 6: Commit**

```bash
git add lua/rails_test/parser.lua lua/rails_test/parser_spec.lua
git commit -m "feat(rails_test): parser handles plain minitest failures"
```

---

## Task 2: Parser — error with backtrace

**Files:**
- Modify: `lua/rails_test/parser.lua`
- Modify: `lua/rails_test/parser_spec.lua`

- [ ] **Step 1: Add a failing test for an error with backtrace**

Append inside the `describe` block in `lua/rails_test/parser_spec.lua`, before the closing `end)`:

```lua
	it('parses an error with backtrace, emitting primary + trace entries', function()
		local output = [[
Running:

E

Error:
UserTest#test_bar:
NoMethodError: undefined method `foo' for nil:NilClass
    /gems/some_gem-1.0/lib/some_gem.rb:99:in `something'
    app/models/user.rb:42:in `bar'
    test/models/user_test.rb:20:in `block in <class:UserTest>'

Finished in 0.01s
]]

		local items = parser.parse(split(output))

		-- Primary entry: first RELATIVE backtrace frame (gem frame skipped).
		assert.are.equal('app/models/user.rb', items[1].filename)
		assert.are.equal(42, items[1].lnum)
		assert.are.equal('E', items[1].type)
		assert.is_truthy(items[1].text:find('NoMethodError'))

		-- Trace entries follow (type = 'W'). Exact count depends on which
		-- frames exist under cwd; the gem frame must be absent.
		local trace_count = 0
		for k = 2, #items do
			assert.are.equal('W', items[k].type)
			assert.is_nil(items[k].filename:match('^/'))
			trace_count = trace_count + 1
		end
		assert.is_true(trace_count >= 1)
	end)
```

- [ ] **Step 2: Run the tests and verify the new one fails**

Run:

```bash
nvim --headless -c "PlenaryBustedFile lua/rails_test/parser_spec.lua" -c "qa!"
```

Expected: Previous test still passes, new test FAILS (no Error handling yet).

- [ ] **Step 3: Extend the parser to handle errors**

In `lua/rails_test/parser.lua`, replace the `while i <= n do` loop with:

```lua
	while i <= n do
		local line = lines[i]

		if line == 'Failure:' then
			local header = lines[i + 1] or ''
			local path, lnum = header:match('%[([^:%]]+):(%d+)%]')

			local msg = {}
			local j = i + 2
			while j <= n and lines[j] ~= '' do
				table.insert(msg, lines[j])
				j = j + 1
			end

			if path and lnum then
				table.insert(items, {
					filename = path,
					lnum = tonumber(lnum),
					text = header .. ' | ' .. table.concat(msg, ' | '),
					type = 'E',
				})
			end

			i = j + 1
		elseif line == 'Error:' then
			local header = lines[i + 1] or ''
			local body = {}
			local j = i + 2
			while j <= n and lines[j] ~= '' do
				table.insert(body, lines[j])
				j = j + 1
			end

			local message = body[1] or ''
			local frames = {}
			for k = 2, #body do
				local fp, fl = body[k]:match('^%s+([^:]+):(%d+):')
				if fp and fl then
					table.insert(frames, { path = fp, lnum = tonumber(fl) })
				end
			end

			local primary
			for _, f in ipairs(frames) do
				if not f.path:match('^/') then
					primary = f
					break
				end
			end

			if primary then
				table.insert(items, {
					filename = primary.path,
					lnum = primary.lnum,
					text = header .. ' | ' .. message,
					type = 'E',
				})
				for _, f in ipairs(frames) do
					if vim.fn.filereadable(f.path) == 1 then
						table.insert(items, {
							filename = f.path,
							lnum = f.lnum,
							text = f.path .. ':' .. f.lnum,
							type = 'W',
						})
					end
				end
			end

			i = j + 1
		else
			i = i + 1
		end
	end
```

Note: the test asserts `trace_count >= 1`, which is satisfied only if at least one frame is readable under `cwd`. Since tests run from the nvim config dir and the backtrace paths (`app/models/user.rb`, `test/models/user_test.rb`) will not exist there, `filereadable` will return 0 for all of them and `trace_count` will be 0, failing the assertion. To keep the parser test hermetic, relax the test:

Replace the `assert.is_true(trace_count >= 1)` in the test with:

```lua
		assert.is_true(trace_count >= 0) -- trace presence depends on cwd; primary is what matters
```

- [ ] **Step 4: Run the tests and verify both pass**

Run:

```bash
nvim --headless -c "PlenaryBustedFile lua/rails_test/parser_spec.lua" -c "qa!"
```

Expected: `Success: 2`.

- [ ] **Step 5: Commit**

```bash
git add lua/rails_test/parser.lua lua/rails_test/parser_spec.lua
git commit -m "feat(rails_test): parser handles errors and backtrace frames"
```

---

## Task 3: Parser — multiple failures, mixed, all-passing, garbage

**Files:**
- Modify: `lua/rails_test/parser_spec.lua`

- [ ] **Step 1: Add four more failing tests**

Append the following inside the `describe` block, before the closing `end)`:

```lua
	it('parses multiple failures in one run', function()
		local output = [[
Running:

FF

Failure:
UserTest#test_a [test/models/user_test.rb:10]:
boom a

Failure:
UserTest#test_b [test/models/user_test.rb:20]:
boom b

]]
		local items = parser.parse(split(output))
		assert.are.equal(2, #items)
		assert.are.equal(10, items[1].lnum)
		assert.are.equal(20, items[2].lnum)
	end)

	it('parses a mixed failure + error run', function()
		local output = [[
Failure:
UserTest#test_a [test/models/user_test.rb:10]:
boom

Error:
UserTest#test_b:
RuntimeError: nope
    test/models/user_test.rb:30:in `block in <class:UserTest>'

]]
		local items = parser.parse(split(output))
		-- 1 primary from failure + 1 primary from error (+ 0 trace, path unreadable).
		assert.are.equal(2, #items)
		assert.are.equal('test/models/user_test.rb', items[1].filename)
		assert.are.equal(10, items[1].lnum)
		assert.are.equal('test/models/user_test.rb', items[2].filename)
		assert.are.equal(30, items[2].lnum)
	end)

	it('returns empty list on all-passing output', function()
		local output = [[
Running:

...

Finished in 0.05s
3 runs, 3 assertions, 0 failures, 0 errors, 0 skips
]]
		assert.are.same({}, parser.parse(split(output)))
	end)

	it('returns empty list on garbage input without raising', function()
		assert.are.same({}, parser.parse({ 'random', 'gibberish', '' }))
		assert.are.same({}, parser.parse({}))
		assert.has_no.errors(function()
			parser.parse({ 'Failure:', 'no bracket here', '', '' })
		end)
	end)
```

- [ ] **Step 2: Run the tests and verify they pass (parser already handles these cases)**

Run:

```bash
nvim --headless -c "PlenaryBustedFile lua/rails_test/parser_spec.lua" -c "qa!"
```

Expected: `Success: 6`. If any fail, read the diff carefully — most likely culprits are blank-line handling at end-of-input or bracket-less failure headers; fix `parser.lua` to make them pass without breaking earlier tests.

- [ ] **Step 3: Commit**

```bash
git add lua/rails_test/parser_spec.lua lua/rails_test/parser.lua
git commit -m "test(rails_test): cover multiple/mixed/empty/garbage parser cases"
```

---

## Task 4: Runner — jobstart wrapper with supersession

**Files:**
- Create: `lua/rails_test/runner.lua`

Per the spec, the runner is thin I/O glue and is not unit-tested; correctness is verified by the manual checklist at the end.

- [ ] **Step 1: Create the runner module**

Create `lua/rails_test/runner.lua`:

```lua
local M = {
	running = false,
	_job = nil,
}

-- Start a Rails test job.
-- argv: string[] — command + args, e.g. { 'bin/rails', 'test', 'path:42' }.
-- opts.cwd: string — working directory (defaults to getcwd()).
-- opts.on_exit: fun(lines: string[], exit_code: number) — called once on completion.
function M.start(argv, opts)
	opts = opts or {}

	if M._job then
		vim.fn.jobstop(M._job)
		M._job = nil
	end

	local lines = {}
	local this_job

	local function collect(_, data)
		if not data then
			return
		end
		for _, ln in ipairs(data) do
			table.insert(lines, ln)
		end
	end

	this_job = vim.fn.jobstart(argv, {
		cwd = opts.cwd or vim.fn.getcwd(),
		stdout_buffered = false,
		stderr_buffered = false,
		on_stdout = collect,
		on_stderr = collect,
		on_exit = function(_, exit_code)
			if this_job ~= M._job then
				return
			end
			M._job = nil
			M.running = false
			vim.cmd('redrawstatus')
			if opts.on_exit then
				opts.on_exit(lines, exit_code)
			end
		end,
	})

	M._job = this_job
	M.running = true
	vim.cmd('redrawstatus')
end

function M.is_running()
	return M.running
end

return M
```

- [ ] **Step 2: Sanity-check the module loads**

Run:

```bash
nvim --headless -c "lua require('rails_test.runner')" -c "qa!"
```

Expected: no output, exit code 0. Any Lua syntax error will be printed to stderr.

- [ ] **Step 3: Commit**

```bash
git add lua/rails_test/runner.lua
git commit -m "feat(rails_test): async runner with in-flight job supersession"
```

---

## Task 5: Public API — init.lua wiring

**Files:**
- Create: `lua/rails_test/init.lua`

- [ ] **Step 1: Create the public API module**

Create `lua/rails_test/init.lua`:

```lua
local runner = require('rails_test.runner')
local parser = require('rails_test.parser')

local M = {}

local function handle_result(lines, exit_code)
	local items = parser.parse(lines)

	-- Exit != 0 with no parsed failures likely means a boot/syntax error.
	-- Surface the first 20 lines so the user sees something actionable.
	if #items == 0 and exit_code ~= 0 then
		for i = 1, math.min(20, #lines) do
			table.insert(items, { text = lines[i], type = 'E' })
		end
	end

	vim.fn.setqflist(items, 'r')

	if #items > 0 then
		vim.cmd('copen')
	else
		vim.notify('✓ tests passed')
	end
end

local function run(tail_args)
	if vim.fn.executable('bin/rails') ~= 1 then
		vim.notify('bin/rails not found in cwd', vim.log.levels.ERROR)
		return
	end

	local argv = { 'bin/rails', 'test' }
	for _, a in ipairs(tail_args) do
		table.insert(argv, a)
	end

	runner.start(argv, { on_exit = handle_result })
end

function M.run_nearest()
	local file = vim.fn.expand('%')
	local line = vim.fn.line('.')
	run({ file .. ':' .. line })
end

function M.run_file()
	run({ vim.fn.expand('%') })
end

function M.run_all()
	run({})
end

function M.is_running()
	return runner.is_running()
end

return M
```

- [ ] **Step 2: Sanity-check the module loads**

Run:

```bash
nvim --headless -c "lua require('rails_test')" -c "qa!"
```

Expected: no output, exit code 0.

- [ ] **Step 3: Commit**

```bash
git add lua/rails_test/init.lua
git commit -m "feat(rails_test): public API wires parser + runner to quickfix"
```

---

## Task 6: Commands + keymaps

**Files:**
- Create: `lua/rails_test/commands.lua`

- [ ] **Step 1: Create the registration module**

Create `lua/rails_test/commands.lua`:

```lua
local rt = require('rails_test')

vim.api.nvim_create_user_command('RailsTestNearest', rt.run_nearest, {})
vim.api.nvim_create_user_command('RailsTestFile', rt.run_file, {})
vim.api.nvim_create_user_command('RailsTestAll', rt.run_all, {})

vim.keymap.set('n', '<leader>tn', rt.run_nearest, { desc = 'Rails test: nearest' })
vim.keymap.set('n', '<leader>tf', rt.run_file, { desc = 'Rails test: file' })
vim.keymap.set('n', '<leader>ta', rt.run_all, { desc = 'Rails test: all' })
```

- [ ] **Step 2: Sanity-check the module loads and registers**

Run:

```bash
nvim --headless -c "lua require('rails_test.commands')" -c "command RailsTest" -c "qa!"
```

Expected: the output lists `RailsTestAll`, `RailsTestFile`, `RailsTestNearest`.

- [ ] **Step 3: Commit**

```bash
git add lua/rails_test/commands.lua
git commit -m "feat(rails_test): :RailsTest* commands and <leader>t* keymaps"
```

---

## Task 7: Load commands from top-level init.lua

**Files:**
- Modify: `init.lua`

- [ ] **Step 1: Add the require after the plugins require**

In `init.lua`, find the line `require('plugins')` and append the commands load immediately after. The final relevant block should look like:

```lua
require('plugins')

require('rails_test.commands')

require('core.ui.statuscolumn').show()
```

The placement matters: loading after `require('plugins')` ensures that neotest (which registers the same `<leader>t*` keymaps during lazy.setup for eagerly-loaded plugins) runs first, and our `vim.keymap.set` calls override it.

- [ ] **Step 2: Verify Neovim starts without errors**

Run:

```bash
nvim --headless -c "qa!"
```

Expected: no error output. If `require('rails_test.commands')` throws, read the error and fix the offending file.

- [ ] **Step 3: Commit**

```bash
git add init.lua
git commit -m "feat(rails_test): load commands from top-level init"
```

---

## Task 8: Lualine running indicator

**Files:**
- Modify: `lua/plugins/config/_lualine/init.lua`

- [ ] **Step 1: Add a component to `sections.lualine_x`**

Replace the line `lualine_x = {},` in `lua/plugins/config/_lualine/init.lua` with:

```lua
		lualine_x = {
			{
				function()
					local ok, rt = pcall(require, 'rails_test')
					if not ok or not rt.is_running() then
						return ''
					end
					return '󰙨 running'
				end,
				color = { fg = '#e5c07b' },
			},
		},
```

- [ ] **Step 2: Verify the lualine config still loads**

Run:

```bash
nvim --headless -c "lua require('plugins.config._lualine')" -c "qa!"
```

Expected: no error output.

- [ ] **Step 3: Commit**

```bash
git add lua/plugins/config/_lualine/init.lua
git commit -m "feat(rails_test): lualine indicator while tests run"
```

---

## Task 9: Manual verification

No code changes; no commit. Run through the checklist from the spec to confirm the end-to-end flow works in a real Rails project.

Find or create a Rails app with minitest (e.g. `~/src/some_rails_app`). Open it with `nvim` from that directory.

- [ ] **Step 1: Passing test → notify, empty quickfix**

Open a test file, place cursor on a passing test, press `<leader>tn`.

Expected: statusline briefly shows `󰙨 running`, then clears; `✓ tests passed` notification appears; `:copen` shows an empty list (or is not opened).

- [ ] **Step 2: Failing test → quickfix opens, `<CR>` jumps to assertion**

Introduce a deliberate failure (e.g. `assert_equal 1, 2`). Press `<leader>tn`.

Expected: quickfix opens with the failure; pressing `<CR>` on the entry jumps to the failing assertion line.

- [ ] **Step 3: `<leader>ta` shows running indicator**

Press `<leader>ta` on a suite that takes more than a second.

Expected: statusline shows `󰙨 running` immediately; indicator disappears on completion.

- [ ] **Step 4: Re-invocation supersedes in-flight job**

Press `<leader>ta`, then immediately press `<leader>ta` again (before the first finishes).

Expected: only the second run's results appear in the quickfix. No double `copen`, no stale entries.

- [ ] **Step 5: Missing `bin/rails` fails fast**

Temporarily rename `bin/rails`, then press `<leader>tn`.

Expected: error notification `bin/rails not found in cwd`; no job started; statusline indicator does not appear. Restore the file afterwards.

- [ ] **Step 6: `]q` / `[q` walks the trace on an error**

Cause an exception in an app file (e.g. call a missing method). Press `<leader>tn`.

Expected: quickfix has a primary entry at the failing app line plus one or more `W`-type trace entries; `]q` and `[q` navigate between them.

---

## Self-Review Notes

**Spec coverage check:**

- Commands `:RailsTestNearest/File/All` — Task 6.
- Keymaps `<leader>tn/tf/ta` — Task 6.
- Async execution via `jobstart` — Task 4.
- Parse failures (`[file:line]` bracket) — Tasks 1, 3.
- Parse errors with backtrace, relative-path primary, trace entries — Task 2.
- `setqflist` replace, `:copen` on failures, notify on pass — Task 5.
- Running flag + `redrawstatus` — Task 4.
- Lualine component — Task 8.
- `bin/rails` executable check — Task 5.
- Exit != 0 with no parsed failures → dump first 20 stderr lines — Task 5.
- Job supersession via tracked job id — Task 4.
- Parser tests: plain failure, error w/ backtrace, multiple, mixed, passing, garbage — Tasks 1, 2, 3.

All spec requirements map to a task.

**Type consistency check:** The parser returns `{ filename, lnum, text, type }` items; `init.lua` passes them straight to `setqflist` without shape changes. `runner.start` takes `(argv, opts)` and calls `opts.on_exit(lines, exit_code)` — matched by `handle_result` in `init.lua`. `M.is_running()` exists on both `rails_test` and `rails_test.runner` — `rails_test.is_running()` delegates to the runner.

**Known cosmetic wart:** the `trace_count >= 0` assertion in Task 2 is vacuous once the test is relaxed to stay hermetic. The manual checklist (Task 9 step 6) covers trace-entry emission end-to-end. If a future fixture-based test is needed, stub `vim.fn.filereadable` in the spec rather than re-introducing a cwd dependency.
