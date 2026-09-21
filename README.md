# Neovim configuration

Personal Neovim configuration, extracted from the dotfiles repository with its history preserved.
The dotfiles repository will consume this repository as a Git submodule at `~/.config/nvim`.

After the A3b code fixes, run these checks from the repository root:

```sh
nvim --headless -c "PlenaryBustedFile lua/rails_test/parser_spec.lua" -c "qa!"
selene lua
```
