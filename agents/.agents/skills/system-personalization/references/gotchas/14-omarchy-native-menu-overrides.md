# Use Native Appearance Menu IDs and Preserve Normalized Row Metadata

- **ID**: `14-omarchy-native-menu-overrides`
- **Category**: System
- **Hardware / Target**: Universal (Omarchy 4.5)
- **Severity**: Warning

## Symptom

A custom Background action is missing from the expected menu, appears as `appearance.background` instead of **Background**, or loses its icon and search aliases.

## Root Cause

The installed native menu's row is `appearance.background`; `style` is an alias for the `appearance` submenu, not its current ID. A `style.background` override does not replace this row.

Although the menu merges rows by ID, `MenuModel.normalizeItem` fills absent fields before that merge. An action-only override is normalized with the ID as its label, an empty icon, and no aliases, overwriting the corresponding stock metadata.

## Solution & Fix

The standalone Aether tool's `integrate --yes` command verifies the installed `appearance.background` ID, copies its stock row metadata, and changes its action to `omarchy-aether background`. It adds that full normalized-compatible row to the existing user JSONC while preserving comments and unrelated settings, with a dated backup. The desired action fragment is versioned universally at `core/.config/omarchy-aether/menu.json`.

Do not replace the native Theme action. A valid user theme with `colors.toml`, a background, and `preview.png` is discovered automatically under `~/.config/omarchy/themes/aether/`.

Stock translations are applied before user overrides; a copied explicit label takes precedence over translations. Keep this in mind when changing menu languages or deliberately retitling the user row. Never edit the packaged menu model to work around user configuration.

## Verification

```sh
omarchy theme list
omarchy-aether integrate --yes --json  # Idempotent when already installed.
```

The project evaluates the installed Omarchy `MenuModel.js` in Qt's JavaScript engine to check that the Background label, icon, aliases, and custom action survive the native merge. On hosts without Omarchy, the portable metadata tests still run.

## Related References

- `/usr/share/omarchy/default/omarchy/omarchy-menu.jsonc`
- `/usr/share/omarchy/shell/plugins/menu/MenuModel.js`
- [Aether native-menu documentation](https://github.com/JValdivia23/omarchy-aether#use-omarchys-normal-menus)
