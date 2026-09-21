# External tools

Neovim bootstraps lazy.nvim and plugins, including Treesitter parsers. It does not install
language servers, linters, formatters or their runtimes, and does not add tool directories to
`PATH`. Provision these outside Neovim through the system/package setup in dotfiles.

This inventory follows the active code and the plugin revisions in `lazy-lock.json`. **Required**
means needed to run Neovim or complete a fresh plugin/parser install. **Optional** means the editor
can run without it, but the named feature needs it. Missing LSP and lint executables are skipped;
missing formatters do not generate availability notifications. This does not conceal failures
from installed but misconfigured tools or missing project libraries.

Unless explicitly marked verified, Fedora sources below are candidates, **unverified on the target Fedora machine**; Block 2 must
confirm package names, repository availability and versions. npm/gem entries identify upstream
distribution channels for provisioning outside Neovim, not install hooks or a claim that Fedora
has no native package. Nothing here is an instruction to install packages from the editor.

## Block 2 provisioning and shared configuration

The dotfiles installer owns the active tool inventory. Fedora RPMs are listed in
its `packages/editor-tools.txt`; asdf owns Node 24.21.0 / Ruby 3.4.10 and their
`default-npm-packages` / `default-gems`. This includes npm jsonlint (not Fedora's
incompatible demjson executable), Standard and vscode-langservers-extracted.
StyLua 2.5.2, Selene 0.31.0 and lf r42 use pinned, SHA-256-verified upstream release
binaries. Shell formatting uses Fedora's `shfmt` with two-space indentation (`-i 2`);
inactive LuaLS and the other dormant tools below are not mandatory packages.

The global RuboCop path is now `$XDG_CONFIG_HOME/rubocop/config.yml`, shared with
RuboCop's own discovery. Project bundles and project configs retain their role.
Stylelint's global fallback passes `--config-basedir` from `npm root -g` at each
invocation; project configuration keeps Stylelint's native discovery. Lint and
Conform use `plugins.config.stylelint` for the same behavior. Codespell's installed
rc owns its ignore/exclusion inputs, so this editor passes only `--config`.
`tests/tooling.lua` checks these consumer contracts before the parser suite.

## Editor, installation and supporting commands

| Binary | Consumer (repository file:line) | Requirement | Likely Fedora source |
|---|---|---|---|
| `nvim` | `tests/run.sh:10`; `init.lua:21` | Required; locked Treesitter documents Neovim 0.12+ | dnf `neovim`; available version unverified |
| `git` | `lua/plugins/bootstrap.lua:8`; `tests/bootstrap.lua:6`; Git plugins in `lua/plugins/plugin_list.lua:393` | Required for plugin bootstrap; also Git features | dnf `git` |
| `curl` | Parser install at `lua/plugins/config/treesitter.lua:32`; HTTP adapter at `lua/plugins/config/codecompanion.lua:34` | Required for fresh parsers; optional for AI requests | dnf `curl` |
| `tar`, `gzip` | Parser install at `lua/plugins/config/treesitter.lua:32` (plugin extracts `.tar.gz` with `tar -xzf`) | Required for fresh parsers | dnf `tar`, `gzip` |
| `tree-sitter` | Parser install at `lua/plugins/config/treesitter.lua:32`; build at `lua/plugins/plugin_list.lua:8` | Required to build parsers; locked plugin documents CLI 0.26.1+ | dnf `tree-sitter-cli` candidate; name/version unverified; not npm |
| `cc` (or a supported C compiler, e.g. `gcc`/`clang`) | Parser compilation triggered by `lua/plugins/config/treesitter.lua:32` | Required to build parsers | dnf `gcc` or `clang` |
| `bash`, `sh` | `tests/run.sh:1`, `tests/with-isolated-xdg.sh:1`; shell commands in `legacy/script.vim:7` | Required for the test scripts and shell-backed features | dnf `bash` |
| `env`, `dirname`, `mktemp`, `mkdir`, `chmod`, `ln`, `rm` | `tests/with-isolated-xdg.sh:4`, `:5`, `:6`, `:10`, `:11`, `:12`, `:16`; `legacy/script.vim:27` | Required for test isolation; `rm` also used by the explicit cell-removal command | dnf `coreutils` |
| `rg` | `lua/plugins/config/far.lua:4`; search pickers at `lua/plugins/plugin_list.lua:103`; `lua/plugins/config/spectre.lua:1` | Optional; required for configured ripgrep search | dnf `ripgrep`; the `BurntSushi/ripgrep` plugin spec only clones sources, it does not supply the binary |
| `fd` or `find` (with `rg` as another picker fallback) | File pickers at `lua/plugins/plugin_list.lua:85`, `:96` (Snacks defaults) | Optional file-discovery alternatives | dnf `fd-find` or `findutils`; exact fallback order is plugin-dependent |
| `sed` | `lua/plugins/config/spectre.lua:1` (Spectre's default replacement engine) | Optional; required for Spectre replacement | dnf `sed` |
| `python3` | UltiSnips plugin at `lua/plugins/plugin_list.lua:290`; Python snippets in `ultisnips/all.snippets:44` | Optional; required for Python-backed snippets, with the Neovim Python provider | dnf `python3`, plus `python3-neovim`/pynvim provider package (name unverified) |
| `node` | ESLint server at `lua/lsp/new.lua:71`; JavaScript lint/format tools below | Optional runtime; required by the relevant npm-distributed tools | dnf `nodejs` |
| `npm` | `lua/plugins/plugin_list.lua:382` installs cmp-npm, whose plugin code invokes npm | Optional completion capability; the current completion-source list does not enable `npm` | dnf `npm` candidate, or Node packaging; unverified |
| `ruby` | `lua/plugins/config/_lint/rubocop.lua:37`; `lua/plugins/config/_neotest.lua:68` | Optional runtime; required by Ruby tooling | dnf `ruby` |
| `bundle` | `lua/plugins/config/_lint/rubocop.lua:37`; `lua/plugins/config/_conform/rubocop.lua:45`; `lua/plugins/config/_neotest.lua:68` | Optional; required for bundled Ruby lint/format/tests | dnf `rubygem-bundler` candidate or gem `bundler` |
| `rails`, project `bin/rails` | `lua/plugins/config/_neotest.lua:70`; `lua/rails_test/init.lua:61`; `legacy/script.vim:7` | Optional; required only for Rails commands, not the parser specs | Project Rails gem/binstub; gem `rails` (dnf availability unverified) |
| `dolphin` | `lua/core/mappings.lua:43` | Optional explicit file-manager shortcut | dnf `dolphin` |
| `man` | `lua/plugins/plugin_list.lua:153` | Optional manual-page picker | dnf `man-db` |
| `xdg-open` or `gio` | `lua/lsp/new.lua:109` (`vim.ui.open`) | Optional desktop URL opener | dnf `xdg-utils` or `glib2` candidate |
| `wl-copy`, `wl-paste` **or** `xclip`/`xsel` | `lua/core/options.lua:45` (`unnamedplus`) | Optional system-clipboard provider, depending on desktop/session | dnf `wl-clipboard`, `xclip` or `xsel` |

The [locked Treesitter README](https://github.com/nvim-treesitter/nvim-treesitter/blob/4916d6592ede8c07973490d9322f187e07dfefac/README.md#requirements)
specifies the parser-build prerequisites. The build callback enables the plugin runtime path,
invalidates Lazy's stale module index and waits for the new `update()` API; plugin commits are unchanged.

## Active language servers, linters and formatters

All tools in this table are **optional for startup, required for the listed feature**. Plugin names
are not always executable names: `standardjs` runs `standard`, and `eslint-lsp` is a package alias,
not a command. Project-local commands may be preferred by plugin defaults (notably Standard,
Prettier and Stylelint); Python lint also checks `.venv/bin` (`lua/plugins/config/_lint/linters.lua:58`).
These paths are discovered, never installed, by Neovim.

| Binary | Consumer (repository file:line) | Requirement / feature | Likely Fedora source |
|---|---|---|---|
| `vscode-eslint-language-server` | `lua/lsp/new.lua:71` | Optional JS/TS/Vue/Svelte LSP, only with an ESLint project root | npm global `vscode-langservers-extracted`; native dnf source unverified |
| `rubocop` | `lua/lsp/new.lua:145`; `lua/plugins/config/_lint/rubocop.lua:41`; `lua/plugins/config/_conform/rubocop.lua:48` | Optional Ruby LSP from PATH; lint/format use `bundle exec rubocop` and need the project gem | gem `rubocop`; dnf `rubygem-rubocop` candidate unverified |
| `shellcheck` | `lua/plugins/config/_lint/init.lua:9` | Optional shell lint | dnf `ShellCheck` candidate (capitalization to confirm) |
| `standard` | `lua/plugins/config/_lint/init.lua:11`; `lua/plugins/config/_conform/init.lua:75` | Optional JS/TS lint and JS formatting | npm global `standard` |
| `selene` | `lua/plugins/config/_lint/init.lua:13`; `tests/run.sh:16` | Optional Lua lint and non-fatal test-runner lint | dnf source/package name **unverified**; resolve in Block 2 |
| `stylelint` | `lua/plugins/config/_lint/init.lua:14`; override at `lua/plugins/config/_lint/linters.lua:19` | Optional SCSS/Sass lint; formatter override exists but is not assigned to a filetype | npm global `stylelint`; project rule/config packages also needed |
| `mypy` | `lua/plugins/config/_lint/init.lua:17`; command at `lua/plugins/config/_lint/linters.lua:73` | Optional Python type checking | dnf `python3-mypy` candidate unverified |
| `pylint` | `lua/plugins/config/_lint/init.lua:17`; command at `lua/plugins/config/_lint/linters.lua:69` | Optional Python lint | dnf `python3-pylint` candidate unverified |
| `slim-lint` | `lua/plugins/config/_lint/init.lua:18`; command at `lua/plugins/config/_lint/slimlint.lua:8` | Optional Slim lint | gem `slim_lint`; dnf source unverified |
| `jsonlint` | `lua/plugins/config/_lint/init.lua:19` | Optional JSON lint | npm global `jsonlint` |
| `codespell` | `lua/plugins/config/_lint/init.lua:20`; options at `lua/plugins/config/_lint/linters.lua:36` | Optional spelling lint on all supported buffers | dnf `codespell` ([Fedora package](https://packages.fedoraproject.org/pkgs/codespell/codespell/index.html)); target release still to verify |
| `stylua` | `lua/plugins/config/_conform/init.lua:70` | Optional Lua formatting | dnf `stylua` candidate; package availability unverified |
| `isort` | `lua/plugins/config/_conform/init.lua:72` | Optional Python import formatting | dnf `python3-isort` candidate unverified |
| `black` | `lua/plugins/config/_conform/init.lua:72` | Optional Python formatting | dnf `python3-black` candidate unverified |
| `prettier` | `lua/plugins/config/_conform/init.lua:74`, `:76`, `:78` | Optional SCSS, JSON and YAML formatting | npm global `prettier` |
| `shfmt` | `lua/plugins/config/_conform/init.lua:74`; indent options at `:22` | Optional shell formatting, two-space indent (`-i 2`) | dnf `shfmt` 3.7.0-5.fc41 ([Fedora 44 source](https://packages.fedoraproject.org/pkgs/golang-mvdan-sh-3/shfmt/fedora-44.html)); `/usr/bin/shfmt` ownership and Conform invocation verified on Fedora 44 |
| `clang-format` | `lua/plugins/config/_conform/init.lua:79` | Optional C formatting | dnf `clang-tools-extra` candidate unverified |

The [upstream server package](https://github.com/hrsh7th/vscode-langservers-extracted#usage)
publishes the `vscode-eslint-language-server` command. The server also needs an ESLint library
and project configuration; Neovim does not invoke an `eslint` CLI directly or install that library.

## Dormant configuration and the old Mason list

`init.lua:21` loads `lsp.new`, which calls `vim.lsp.start` for only ESLint and RuboCop. The older
`lua/lsp/init.lua:28` wrapper around `vim.lsp.config` is not required by the active configuration.
The following are **not required by the current configuration**; do not turn the old installation
list into mandatory dependencies. Sources are unverified provisioning candidates only.

| Binary | Dormant evidence / absent consumer | Requirement | Likely source if deliberately enabled later |
|---|---|---|---|
| `lua-language-server` | Unreached `lua/lsp/config.lua:6`, `lua/lsp/servers/lua_ls.lua:3` | Optional, inactive | dnf source/package name unverified |
| `vscode-css-language-server` (old `css-lsp`) | Commented registration at `lua/lsp/config.lua:10` | Optional, inactive | npm global `vscode-langservers-extracted` |
| `vscode-json-language-server` | Unreached `lua/lsp/config.lua:7` | Optional, inactive | npm global `vscode-langservers-extracted` |
| `typescript-language-server` | Unreached `lua/lsp/config.lua:9`, also disabled at `:15` | Optional, inactive | npm global `typescript-language-server` plus `typescript` |
| `pylsp` | Commented registration at `lua/lsp/config.lua:12`; command in `lua/lsp/servers/pylsp.lua:5` | Optional, inactive | dnf `python3-lsp-server` candidate unverified |
| `solargraph` | Unreferenced command in `lua/lsp/servers/solargraph.lua:4` | Optional, inactive | gem `solargraph` |
| `rustfmt` | No current consumer; old list only | Not required | dnf `rustfmt` candidate unverified |
| `vim-language-server` | No current consumer; old list only | Not required | npm global `vim-language-server` |
| `yaml-language-server` | No current consumer; old list only | Not required | npm global `yaml-language-server` |

The other old entries remain active under the actual executable names in the preceding table:
codespell, ESLint LSP, jsonlint, prettier, rubocop, selene, shellcheck, stylua and Standard.
Whitespace trimming (`lua/plugins/config/_conform/init.lua:80`) uses a built-in formatter and
needs no external binary.

## What `tests/run.sh` needs

- Required: `bash`, `env`, `dirname`, `mktemp`, `mkdir`, `chmod`, `ln`, `rm`, `nvim` and `git`.
  The runner clears the environment except PATH, creates fresh HOME/XDG directories, and downloads
  plugins at their locked commits. Network access is needed for each fresh run.
- Full fresh parser installation additionally needs `curl`, `tar`, `gzip`, `tree-sitter` and a C
  compiler. Parser installation is asynchronous; passing the six parser specs alone does not prove
  every Treesitter parser finished installing.
- Optional: `selene`. If available, `selene lua` prints its findings and a non-fatal summary. If
  absent, the runner prints a skip. The script returns the spec process's exit status even when
  Selene reports the deliberately deferred 9 errors and 33 warnings.
- `shellcheck` is only needed for the separate shell-script check shown in `README.md:30`;
  `tests/run.sh` does not invoke it. Rails, Bundler, Ruby, language servers and the other lint/format
  tools are not needed by the pure Lua parser specs.

For a dependency-independent run, supply a deliberate system PATH, for example
`PATH=/usr/bin:/bin ./tests/run.sh`. Do not include a legacy Mason directory. Existing machine-local
tools can be checked separately, but they are not evidence that Fedora supplies the dependencies.
