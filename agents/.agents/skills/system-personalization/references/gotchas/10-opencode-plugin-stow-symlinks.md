# OpenCode Local Plugin Entrypoints & Stow Symlinks

- **ID**: `10-opencode-plugin-stow-symlinks`
- **Category**: System
- **Hardware / Target**: Universal
- **Severity**: Info

## Symptom

A configured local plugin is silently absent from `opencode plugin list`, even
though its package directory and entrypoint exist and its config is loaded.

## Root Cause

OpenCode 2.2.5 resolves the real paths of a local package directory and its
entrypoint, then requires the entrypoint to be inside the directory. With
`stow --no-folding`, a real directory in `~/.config` contains individual file
symlinks into `~/dotfiles`. The resolved entrypoint is outside that apparent
package root, so OpenCode's configuration source scanner omits the plugin.

## Solution & Fix

Configure the actual package directory in dotfiles. For the sudo plugin:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "plugins": ["{env:HOME}/dotfiles/core/.config/opencode/vendor/opencode-sudo"]
}
```

A symlink of the whole package directory also works, because its real directory
and entrypoint share a root. This repository's installer uses `--no-folding`,
so referencing the actual source directory is durable across restows.

Reload configuration with `/reload` when editing through symlinks.

## Verification

Run `opencode plugin list`. `/api/plugin` should show `source.type: local`,
`state.status: active`, and the expected server/TUI/RPC features.

## Related References

- [OpenCode V2 plugin configuration](https://opencode.ai/v2/docs/plugins)
- [OpenCode 2.2.5 source containment check](https://github.com/anomalyco/opencode/blob/v2.2.5/packages/core/src/config/plugin/source.ts)
- [Sudo plugin language adaptation](09-opencode-sudo-language.md)
