# Remove Stale Split-Debug Archives Before Reinstalling a Release Package

- **ID**: `13-makepkg-stale-debug-archives`
- **Category**: System
- **Hardware / Target**: Universal (Arch / Omarchy)
- **Severity**: Info

## Symptom

After switching a local PKGBUILD to `options=('!debug')`, `makepkg -fsi` still installs an old `<package>-debug` package from a previous build of the same version. Its build timestamp remains older than the release package's timestamp.

## Root Cause

The installed makepkg's package-install step includes an existing `${pkg}-debug-${fullver}-${pkgarch}${PKGEXT}` archive from `PKGDEST` based on file existence. Disabling creation of a new debug package does not remove the previously generated archive, so that stale archive can still be selected by `-i`.

## Solution & Fix

For the `omarchy-aether` development build, the PKGBUILD disables split debug output. Removed only the newly generated `omarchy-aether-debug-0.1.0-1-x86_64.pkg.tar.zst` archive from its project build directory, then removed the matching temporary debug package. The actual release package remains installed.

When handling another project, inspect its exact package name, full version, architecture, `PKGDEST`, and archive ownership first. Remove only that project's obsolete generated archive; never clear shared package directories or remove unrelated debug packages.

## Verification

```sh
pacman -Q omarchy-aether
pacman -Q omarchy-aether-debug  # Expected: not installed after cleanup.
```

## Related References

- `/usr/bin/makepkg`, package installation's existing debug-archive check
- [Aether PKGBUILD](https://github.com/JValdivia23/omarchy-aether/blob/main/pkgbuild/PKGBUILD)
