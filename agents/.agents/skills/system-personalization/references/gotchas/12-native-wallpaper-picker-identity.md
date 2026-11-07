# Preserve Wallpaper Identity Across Cached Random Picker Batches

- **ID**: `12-native-wallpaper-picker-identity`
- **Category**: System
- **Hardware / Target**: Universal (Omarchy 4.5)
- **Severity**: Warning

## Symptom

A random wallpaper picker can hide different images with the same basename, repeatedly regenerate thumbnails after shuffling, or produce a broken wallpaper link after switching themes.

## Root Cause

- Omarchy's `ImagePickerModel.loadRows` deduplicates rows by basename, not full source path.
- Cache keys based on rotating pool slots or changing aliases do not identify the original image consistently.
- Omarchy replaces `~/.local/state/omarchy/current/theme/` during a theme switch. A new theme that links directly into that directory can delete its own wallpaper source as it activates.

## Solution & Fix

The standalone `omarchy-aether` project uses stable, unique basename aliases for native picker rows and persistent thumbnails keyed by canonical original path, file size, modification time, and preview format. It sends explicit cached rows through the native image-selector IPC, so shuffled batches do not require scanning or decoding the full library on each open.

Stable library originals are linked into generated themes. Images inside the replaceable current/generated theme directory are copied before publication, preserving the source across the native theme swap. Originals are never modified. Batch preparation runs separately at low priority; the visible batch remains fixed until dismissal.

## Verification

```sh
cd ~/Projects/omarchy-aether
bin/build
bin/test
```

The tests cover duplicate basenames, stable thumbnail keys, original-file protection, and restaging an image from a directory being replaced. They run with temporary roots and an injected native-shell interface, without applying a desktop theme.

## Related References

- [Project validation notes](https://github.com/JValdivia23/omarchy-aether/blob/main/docs/validation.md)
- [Configuration paths](../config-paths.md)
