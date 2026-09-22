# Neovim configuration

Personal Neovim configuration, extracted from the dotfiles repository with its history preserved.
The dotfiles repository will consume this repository as a Git submodule at `~/.config/nvim`.

Run the parser spec and Lua lint from the repository root:

```sh
./tests/run.sh
```

The runner creates a temporary home, `TMPDIR`, and separate XDG config, data, state, cache and runtime
directories, symlinks this repository as `config/nvim`, and clears inherited environment variables
except `PATH`. It removes the temporary environment on exit. Plugins install at their locked
revisions on the first run; allow several minutes and network access. Lazy writes a temporary
copy of the lockfile. `selene lua` runs when Selene is on `PATH`, otherwise the runner reports a skip.
The exit status reflects the specs; lint findings are reported but are non-fatal. The existing
9 Selene errors and 33 warnings are deliberately deferred, including duplicate JavaScript highlight
keys and `if_same_then_else` in the Rails test module.

Check the theme on a real first install and a second start in the same isolated environment:

```sh
./tests/theme-startup.sh
```

This installs all locked plugins from scratch, checks startup errors and the configured palette,
and verifies that repeated theme application preserves plugin highlights. It also exercises
`ColorScheme` and `User LazyDone` recovery. Network access and GNU `timeout` are required.

Language servers, linters and formatters must be supplied externally; Neovim only bootstraps its
plugin manager and plugins (including Treesitter parsers). See [the external tool manifest](docs/external-tools.md)
for the active dependencies and test prerequisites.

Reuse the same isolation for other checks (the bootstrap protects the repository lockfile):

```sh
./tests/with-isolated-xdg.sh nvim --headless \
  --cmd 'lua dofile("tests/bootstrap.lua")' -c 'qa!'
shellcheck tests/run.sh tests/with-isolated-xdg.sh
```
