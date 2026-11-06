# Local English UI adaptation

Source: [maakhai/opencode-sudo](https://github.com/maakhai/opencode-sudo),
commit `ec093cffd25472eec08f7097f2f53b62c10dd0cb` (version 0.1.0).
The upstream MIT license and README are retained.

This copy translates the TUI dialogs, status display, notifications, and
server/helper errors into English to match the current OpenCode terminal UI.
Time formatting uses the runtime's default locale instead of forcing `pt-BR`.

OpenCode 2.2.5's TUI plugin context exposes no interface-language or translation
API, and its CLI settings have no language option. This is an English adaptation,
not automatic synchronization with a future language selector. When such an API
becomes available, use it for translated strings and time formatting.

The local package is selected by `../../opencode.json` using the actual
`$HOME/dotfiles/core/.config/opencode/vendor/opencode-sudo` directory. This avoids
OpenCode's entrypoint containment check rejecting individual Stow symlinks whose
targets are outside the apparent package directory. The config is deployed with
GNU Stow; the source path also works after `install.sh` restows with `--no-folding`.
Authentication and caching behavior follow the pinned upstream source.
To update, compare a new upstream revision with this copy and reapply the text
changes in `src/tui.tsx`, `src/index.ts`, and `src/runtime.ts`.
