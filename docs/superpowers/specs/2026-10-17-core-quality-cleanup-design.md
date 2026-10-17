# Core Quality Cleanup Design

## Goal

Replace the unsafe or obsolete core helpers identified in the review with explicit Neovim-native behavior, without adding host dependencies.

## Decisions

- XML files must not be modified when opened. `:FormatXML` explicitly expands adjacent tags and synchronously indents the current buffer.
- SVG indentation remains native to Neovim and runs synchronously from Conform's format-on-save decision path, after its existing disable and size guards.
- External file changes are detected with `checktime` on `FocusGained` and `BufEnter` for normal buffers only. Saving a buffer is not a refresh trigger.
- Normal-mode `p` and `P` use Vim's native indent-adjusting paste commands for non-YAML buffers while retaining ordinary paste behavior for YAML. Counts and explicit registers must be preserved.
- Configuration reload code is removed. Neovim 0.12's native `:restart` is the supported reload mechanism.
- The unused codespell helper and mapping table are removed; codespell remains integrated through nvim-lint and the shared codespell configuration.
- The Packer-era lazy loader and Packer availability helper are removed. Gitsigns uses lazy.nvim's native buffer events; Treesitter remains eager.

## Constraints

- Do not add a host-level program or project dependency.
- Preserve unrelated configuration behavior and existing user changes.
- Keep tests runnable in the repository's isolated XDG environment.

