# Refresh Terminal-Derived OpenCode Colors Without Signaling Its Service

- **ID**: `17-opencode-exe-theme-refresh`
- **Category**: System
- **Hardware / Target**: Universal (Omarchy / OpenCode V2)
- **Severity**: Warning

---

## Symptom

Aether changes the wallpaper, `colors.toml`, and generated terminal configuration, but an already-open OpenCode window can retain its previous colors despite using the `system` theme.

## Root Cause

Omarchy's packaged `omarchy-restart-opencode` searches for the exact process name `opencode`. The npm/mise installation of OpenCode 2.2.5 runs as `opencode.exe` on Linux, so that helper silently skips it. The OpenCode TUI caches its terminal-derived palette and needs to query the terminal again after a color change.

The installed TUI's theme-refresh subscription handles `SIGUSR2`, clears its palette cache, and queries the terminal again. Its background service uses the same executable name but does **not** register that handler. A blanket `killall -SIGUSR2 opencode.exe` can terminate the service and must not be used.

## Solution & Fix

- Keep OpenCode's existing `theme.name = "system"`; do not generate an app-specific replacement palette.
- The universal helper at `core/.local/bin/omarchy-opencode-theme-refresh` accepts both executable names but signals only current-user interactive TUIs with matching stdin/stdout PTYs and a registered `SIGUSR2` handler. It excludes service invocations and rechecks eligibility after opening a Linux pidfd, preventing PID reuse from redirecting a signal.
- The native `theme-set.d/20-opencode-system-refresh` hook invokes that helper **after** Omarchy finishes terminal retints. This also avoids querying the old palette while the stock visible-app reloads run in parallel.
- The hook was installed through `omarchy hook install theme-set` and linked to its universal `core/` backing file with GNU Stow. The packaged Omarchy helper, Aether policy, wallpapers, OpenCode settings, and background service are not modified.

## Verification

```sh
~/.local/bin/omarchy-opencode-theme-refresh --dry-run --json
python -B -m unittest discover -s tests -p 'test_opencode_theme_refresh.py' -v
```

The 11 isolated regression tests cover both names, service exclusion, ownership, signal-handler checks, PTY validation, incomplete metadata, process replacement/exit races, native hook invocation, and actual pidfd signaling of a disposable test process. They never signal personal sessions.

With approval, running the helper without `--dry-run` refreshed two existing TUI processes while leaving the service alive. OpenCode's `latest/tui/system-theme.json` cache matched the current foreground, background, and all 16 ANSI entries afterward. This cache is diagnostic state, not a configuration file to edit.

A subsequent user-selected **Appearance → Background** change was observed passively with inotify. Aether reapplied the same named theme with a new generation, the refresh hook/helper ran, and OpenCode's cached background changed from teal `#0d1818` to plum `#1a141a` about 1.1 seconds after the new system palette was published. All 16 cached colors matched, and the user confirmed the visible window updated. No additional configuration change was needed for this acceptance check. A constant theme name does not imply this menu skips `theme-set`.

Always identify the entry point before diagnosing a missed refresh. The integrated Appearance menu regenerates Aether colors, while Omarchy's stock desktop double-click route uses an image-only background setter. Also distinguish subtle ANSI-family changes from the separate system accent, which can move much more dramatically.

To disable the automatic workaround, remove only the `20-opencode-system-refresh` hook from the live `theme-set.d/` directory. Reevaluate its necessity if an Omarchy update fixes process discovery upstream.

## Related References

- [OpenCode V2 system colors](https://opencode.ai/v2/docs/cli/theme#system-colors)
- `/usr/share/omarchy/bin/omarchy-restart-opencode` (read-only)
- `/usr/share/omarchy/bin/omarchy-theme-set` (read-only)
- [`../config-paths.md`](../config-paths.md)
