# OpenCode Sudo Plugin Hard-Coded Portuguese UI

- **ID**: `09-opencode-sudo-language`
- **Category**: System
- **Hardware / Target**: Universal
- **Severity**: Info

## Symptom

The sudo plugin displays Portuguese dialogs and notifications while OpenCode's
terminal interface is in English, even with `LANG=en_US.UTF-8`.

## Root Cause

`maakhai/opencode-sudo` at `ec093cffd25472eec08f7097f2f53b62c10dd0cb`
hard-codes Portuguese strings and `pt-BR` time formatting. OpenCode 2.2.5's TUI
plugin context has no UI-language or translation API, and `cli.json` has no
language setting. The GUI plugin locale API is a separate interface.

## Solution & Fix

Use the English adaptation in
`core/.config/opencode/vendor/opencode-sudo/`, selected by the global OpenCode
configuration. Its dialogs, status/toasts, and server/helper errors are English;
times use the runtime's default locale. This matches the current English TUI,
but does not implement automatic synchronization with future UI languages.

Keep local edits in dotfiles rather than modifying OpenCode's package cache.
See the plugin's `LOCAL.md` for its pinned source revision and update procedure.
After changing a symlinked config, use `/reload` if the watcher misses the edit.

## Verification

Run `opencode plugin list` and check that `opencode-sudo` has a local source.
In the TUI, `/sudo status` should display English labels such as `policy`,
`cache`, and `pending requests`.

## Related References

- [Upstream plugin](https://github.com/maakhai/opencode-sudo)
- [OpenCode V2 TUI plugin API](https://opencode.ai/v2/docs/build/plugins/cli)
- [Stow plugin deployment](10-opencode-plugin-stow-symlinks.md)
