# Core Quality Cleanup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace unsafe core autocmds and obsolete helpers with explicit, synchronous, Neovim-native behavior.

**Architecture:** Keep buffer transformations in `core.utils`, expose XML formatting as a user command, and let Conform own save-time SVG formatting. Use native normal commands and lazy.nvim specification keys instead of feedkeys or Packer-era loaders.

**Tech Stack:** Lua, Neovim 0.12 APIs, conform.nvim, lazy.nvim, headless Neovim tests

**Spec:** `docs/superpowers/specs/2026-10-17-core-quality-cleanup-design.md`

## Global Constraints

- Do not add a host-level program or project dependency.
- Preserve unrelated configuration behavior and existing user changes.
- Run tests through `tests/with-isolated-xdg.sh`.

## Review Focus

- Opening an XML file leaves both its text and modified state untouched.
- Explicit-register and counted paste preserve the selected register and count.
- YAML paste remains byte-for-byte ordinary `p`/`P` behavior.
- Disabled Conform autoformat also suppresses SVG indentation.
- `checktime` ignores terminal, help, and other non-file buffers.

---

### Task 1: Explicit XML formatting

**Files:**
- Create: `tests/core.lua`
- Modify: `tests/run.sh`
- Modify: `lua/core/utils.lua`
- Modify: `lua/core/global_cmds.lua`
- Modify: `lua/core/autocmds.lua`

**Interfaces:**
- Produces: `require('core.utils').autoindent(bufnr)` and `require('core.utils').format_xml(bufnr)`; user command `:FormatXML`

- [ ] Write headless tests proving XML reads are non-mutating and `:FormatXML` expands adjacent tags and finishes indentation before returning.
- [ ] Run `tests/with-isolated-xdg.sh nvim --headless -u NONE -i NONE -l tests/core.lua`; expect the new XML assertions to fail because the read autocmd mutates XML and the command does not exist.
- [ ] Implement buffer-scoped synchronous indentation and XML formatting, register `:FormatXML`, and remove the XML read autocmd.
- [ ] Run the targeted headless test; expect all Task 1 assertions to pass.
- [ ] Commit the test and Task 1 implementation.

### Task 2: Conform-owned SVG indentation

**Files:**
- Modify: `tests/core.lua`
- Modify: `lua/core/autocmds.lua`
- Modify: `lua/plugins/config/_conform/init.lua`
- Modify: `lua/plugins/plugin_list.lua`

**Interfaces:**
- Consumes: `require('core.utils').autoindent(bufnr)` from Task 1
- Produces: Conform `format_on_save(bufnr)` that synchronously indents SVG buffers only when autoformat is enabled

- [ ] Add tests that invoke the captured Conform setup callback and prove SVG indentation completes synchronously, respects the disable flag, and Conform loads on `BufWritePre`.
- [ ] Run the targeted headless test; expect failure because SVG indentation is still owned by an asynchronous autocmd and the plugin event is `BufWrite`.
- [ ] Call `autoindent(bufnr)` inside Conform's guarded format-on-save path, remove the SVG autocmd, and change Conform's lazy event to `BufWritePre`.
- [ ] Run the targeted headless test; expect all Task 2 assertions to pass.
- [ ] Commit Task 2.

### Task 3: Safe refresh and native paste

**Files:**
- Modify: `tests/core.lua`
- Modify: `lua/core/autocmds.lua`
- Modify: `lua/core/mappings.lua`
- Modify: `lua/core/utils.lua`

**Interfaces:**
- Produces: refresh autocmds on `FocusGained` and `BufEnter` for normal buffers; expression mappings returning `]p`, `[p`, `p`, or `P`

- [ ] Add real-buffer tests proving an externally changed file reloads on refresh and paste preserves explicit registers, counts, and YAML behavior.
- [ ] Run the targeted headless test; expect failures from the false `buftype` check and clipboard-hardcoded paste helper.
- [ ] Fix refresh with a named augroup and buffer-local `buftype` check; replace feedkey paste helpers with expression mappings using native paste commands.
- [ ] Run the targeted headless test; expect all Task 3 assertions to pass.
- [ ] Commit Task 3.

### Task 4: Remove obsolete reload, codespell, and Packer code

**Files:**
- Modify: `tests/core.lua`
- Modify: `lua/core/global_cmds.lua`
- Modify: `lua/core/utils.lua`
- Modify: `lua/core/mappings.lua`
- Delete: `lua/core/lazy_load.lua`
- Modify: `lua/plugins/plugin_list.lua`

**Interfaces:**
- Produces: Gitsigns lazy.nvim events `{ 'BufReadPre', 'BufNewFile' }`; native `:restart` remains the reload path

- [ ] Add configuration tests proving Gitsigns declares native buffer events and the removed auto-source behavior no longer runs on config writes.
- [ ] Run the targeted headless test; expect failure because Gitsigns is eager and the config auto-source autocmd remains.
- [ ] Delete the Packer loader, `is_available`, codespell helper/mapping, `_G.ReloadConfig`, and config auto-source autocmd; add Gitsigns events.
- [ ] Run the targeted headless test and `tests/run.sh`; expect the targeted checks and full functional suite to pass, with only documented pre-existing non-fatal lint debt.
- [ ] Commit Task 4.

### Final verification

- [ ] Run `stylua --check lua tests/core.lua`.
- [ ] Run `selene lua/core lua/plugins/config/_conform lua/plugins/plugin_list.lua` and confirm no new diagnostics; removed Packer/codespell/reload warnings must be absent.
- [ ] Run `git diff --check`.
- [ ] Run `tests/run.sh` and compare its functional results with the clean baseline.
