# Keep the Custom Aether Tool Separate from Omarchy's Packaged Aether

- **ID**: `11-aether-command-name-collision`
- **Category**: System
- **Hardware / Target**: Universal (Omarchy)
- **Severity**: Warning

## Symptom

A new wallpaper/theme project named Aether risks replacing or shadowing `/usr/bin/aether` and its launcher identity.

## Root Cause

Omarchy already installs the `aether` desktop-theming package (`omacom/aether`). On this machine, `/usr/bin/aether` belongs to `aether 4.32.0-2`. The older Surface dynamic theme also uses the theme slug `aether`, which is independent of that package's executable name.

## Solution & Fix

The new standalone project at `~/Projects/omarchy-aether` consistently uses `omarchy-aether` for its binary, Arch package, Wayland app ID, desktop filename, and icon. Its display name is **Aether Palette**. Do not uninstall, replace, or shadow the packaged `aether` application. Generated theme directories with the existing `aether` slug must be protected if they are not marked as owned by the new generator.

This is a universal user feature, not an XPS or Surface hardware setting. Track its dependencies in `core/`; keep the application source in its separate repository.

## Verification

```sh
pacman -Qo /usr/bin/aether
pacman -Qo /usr/bin/omarchy-aether
```

## Related References

- [Project repository](https://github.com/JValdivia23/omarchy-aether)
- [Configuration paths](../config-paths.md)
