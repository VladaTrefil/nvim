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

Reuse the same isolation for other checks (the bootstrap protects the repository lockfile):

```sh
./tests/with-isolated-xdg.sh nvim --headless \
  --cmd 'lua dofile("tests/bootstrap.lua")' -c 'qa!'
shellcheck tests/run.sh tests/with-isolated-xdg.sh
```
