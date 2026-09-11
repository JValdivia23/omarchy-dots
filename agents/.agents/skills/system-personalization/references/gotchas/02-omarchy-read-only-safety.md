# Omarchy Package Space Read-Only Safety (`/usr/share/omarchy/`)

- **ID**: `02-omarchy-read-only-safety`
- **Category**: `System`
- **Hardware / Target**: `Universal (Omarchy Quattro)`
- **Severity**: `Critical`

---

## Symptom
A developer or AI assistant directly modifies scripts, configurations, themes, or shell plugins under `/usr/share/omarchy/` (for example `/usr/share/omarchy/bin/`, `/usr/share/omarchy/default/`, `/usr/share/omarchy/themes/`, or `/usr/share/omarchy/shell/`). Upon running `omarchy update` or during a package upgrade, all customized files are completely overwritten, reverting customizations back to upstream distribution defaults without backup.

## Root Cause
`/usr/share/omarchy/` is the vendor package installation tree managed directly by Arch Linux's `pacman` and the `omarchy` package. In the Linux Filesystem Hierarchy Standard (FHS), files in `/usr/share/` belong to the distribution and are replaced wholesale during package updates.

## Solution & Fix
Strictly adhere to the separation between distribution package space and user customization space:

1. **NEVER modify `/usr/share/omarchy/` directly.** Treat this directory as strictly read-only.
2. **Reading `/usr/share/omarchy/` is encouraged.** Inspecting files in `/usr/share/omarchy/` is safe and invaluable for learning how Omarchy commands operate, checking default Hyprland configurations, and finding stock themes.
   ```bash
   # Safe to inspect:
   cat /usr/share/omarchy/default/hypr/hyprland.lua
   cat /usr/share/omarchy/bin/omarchy-theme-set
   ```
3. **Always edit user configuration files in `~/.config/`**:
   - Hyprland configs: `~/.config/hypr/` (`bindings.lua`, `input.lua`, `monitors.lua`, `looknfeel.lua`)
   - Omarchy shell & bar: `~/.config/omarchy/shell.json`
   - Custom themes: `~/.config/omarchy/themes/<custom-theme>/`
   - Custom automation hooks: `~/.config/omarchy/hooks/`
   - Cloned plugins: `~/.config/omarchy/plugins/` (use `omarchy plugin clone <plugin>`)
4. **Restoring to Defaults**: When configurations become broken and need resetting, use Omarchy's safe refresh commands which automatically create timestamped backups:
   ```bash
   omarchy refresh shell
   omarchy refresh hyprland
   ```

## Verification
Confirm that no files in `/usr/share/omarchy/` have been altered by checking package integrity:
```bash
pacman -Qk omarchy 2>/dev/null || true
```

## Related References
- [`references/config-paths.md`](../config-paths.md)
- Omarchy Skill: [`~/.agents/skills/omarchy/SKILL.md`](file:///home/jmvp/.agents/skills/omarchy/SKILL.md)
