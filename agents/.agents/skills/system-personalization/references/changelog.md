# System Personalization Changelog

A dated log of all package changes, configurations, script modifications, and hardware upgrades.

## [2.24.0] - 2026-11-11
### Added
- **NanoKVM-USB Serial Permission (Device-Specific, XPS Controller)**:
  - With explicit user approval, installed `/etc/udev/rules.d/70-nanokvm-usb.rules` as `root:root`, mode `0644`, matching only USB vendor/product `1a86:55d3` and serial `5C82073583` with `TAG+="uaccess"`.
  - Grants the active local desktop user access to this unit's serial interface without adding serial-device group membership or granting world access. Native `cdc_acm` was already working; no packages or drivers were installed.
  - Recorded profile-specific gotcha `profiles/xps/gotchas/03-nanokvm-usb-serial-access.md` and indexed it in the personalization references. Updated the separate project guide in `~/Work/nanoKVM/` with verified setup status and safe diagnostic instructions.

### Fixed
- **NanoKVM Serial Access Denied Despite Working Video**:
  - Changed effective read/write access from false to true by reloading udev rules and emitting a change event only for the verified NanoKVM serial sysfs node. No reconnect, reboot, target reset, or general device trigger was needed.

### Verification
- `udevadm verify /etc/udev/rules.d/70-nanokvm-usb.rules` passed; the installed rule is root-owned and mode `0644`.
- `getfacl` confirms `user:jairo:rw-` on the serial device; Python `os.access` confirms read/write access. Original `root:uucp` ownership and mode `0660` remain intact.
- Separately captured the real target desktop at 1920 × 1080. During the initial permission verification, no serial port was opened and no target input was sent.
- Follow-up, separately user-approved input verification: a temporary standard-library Python helper using Sipeed's documented 57600-baud HID protocol confirmed target USB connectivity, visibly positioned the pointer, opened Kitty with Super + Enter, and executed the visually checked `echo nanokvm-terminal-ok` on the CachyOS target. Captured the expected output and a new fish prompt; no target packages or system settings changed.
- Recorded the observed display-focus issue: acknowledged input initially produced no visible terminal until the pointer was placed on the captured output. Updated the profile gotcha and project instructions with focus checks, key-release requirements, and the distinction between KVM control and a native remote shell. Clicks/scroll, BIOS input, and the browser UI remain untested.

## [2.23.0] - 2026-11-11
### Added
- **Webcam QR Code Scanner (`core/.local/bin/camera-qr`, `core/.local/share/applications/camera-qr.desktop`)**:
  - Added lightweight webcam QR scanner script utilizing the pre-installed `zbarcam` utility.
  - Automatically reads single QR codes from the webcam (`/dev/video0`), copies the decoded string to the Wayland clipboard (`wl-copy --sensitive`), and triggers an Omarchy desktop notification via `omarchy-notification-send`.
  - Added a `.desktop` application entry (`Scan QR Code`) with `Icon=camera-photo` in `~/.local/share/applications/` so it is directly launchable from the application launcher (Walker / Rofi).
  - Configured Hyprland window rule in `core/.config/hypr/hyprland.lua` (`o.window("^zbar$", { float = true, center = true })`) to float and center the camera viewfinder window rather than tiling it.
- **GNOME Snapshot Camera App (`core/packages.txt`)**:
  - Installed GNOME `snapshot` (51.0-1) via `pkexec pacman -S --needed snapshot` to provide a modern, dedicated camera photo and video recording application.
  - Tracked `snapshot` and `zbar` in `core/packages.txt` so camera and QR scanner tools are preserved across machine profiles and deployments.

## [2.22.0] - 2026-11-07
### Changed
- **Updated ArtCraft Office & PDF Suite (`core/packages.txt`)**:
  - Upgraded **WordCraft** (`wordcraft-bin`): `0.15.1-1` -> `0.16.0-1`.
  - Upgraded **GridCraft** (`gridcraft-bin`): `0.16.0-1` -> `0.17.0-1`.
  - Upgraded **DeckCraft** (`deckcraft-bin`): `0.15.1-1` -> `0.16.0-1`.
  - Upgraded **PdfCraft** (`pdfcraft-bin`): `0.18.2-1` -> `0.19.0-1`.
  - Verified that all associated headless CLIs ([`wordcraft-cli`](file:///usr/bin/wordcraft-cli), [`gridcraft-cli`](file:///usr/bin/gridcraft-cli), [`deckcraft-cli`](file:///usr/bin/deckcraft-cli), and [`pdfcraft-cli`](file:///usr/bin/pdfcraft-cli)) execute cleanly and report their upgraded versions.

## [2.21.0] - 2026-11-06
### Added
- **XPS Copilot Dual-Role Modifier via `keyd` (`profiles/xps/`)**:
  - Installed `keyd` (tracked in `profiles/xps/packages.txt`) to intercept the hardware-level `Left Super + Left Shift + F23` chord emitted by the Dell XPS 13 (`DX13260`) Copilot key.
  - Configured `/etc/keyd/default.conf` with `leftmeta+leftshift+f23 = overload(meta, compose)` and deployed `/etc/libinput/local-overrides.quirks` (`AttrKeyboardIntegration=internal`) via `profiles/xps/setup.sh` to preserve touchpad palm rejection. Used `compose` (`KEY_COMPOSE` / 127) rather than `menu` (`KEY_MENU` / 139) because XKB maps `<COMP>` (135) to keysym `Menu` (recognized by Flea, browsers, and desktop apps), whereas `KEY_MENU` maps to `XF86MenuKB`.
  - Enables clean dual-role behavior strictly isolated to the XPS profile: tapping Copilot alone sends `Menu` (pops open the active application's context menu), while holding Copilot and pressing another key cleanly acts as `Super` without physical `Shift` interference (`Copilot + Return` -> Terminal, `Copilot + Space` -> launcher, `Copilot + W` -> Close window).
  - Resource usage: ~39 MB RSS, 0% CPU idle.

### Verification
- `systemctl status keyd` (active and running)
- `ps -C keyd -o pid,%cpu,%mem,rss,vsz,cmd`
- `hyprctl configerrors` (clean, 0 errors)

## [2.20.0] - 2026-11-06
### Fixed
- **OpenCode System-Color Refresh After Theme Changes (Universal User Setting)**:
  - Confirmed Omarchy's exact-name `opencode` reload helper misses the npm/mise OpenCode 2.2.5 executable named `opencode.exe`, even though its TUI already uses the terminal-derived `system` theme.
  - Added `core/.local/bin/omarchy-opencode-theme-refresh` and the native `core/.config/omarchy/hooks/theme-set.d/20-opencode-system-refresh` hook with explicit user approval. Refreshes run after terminal retints and target only current-user interactive windows with a registered `SIGUSR2` handler, matching PTYs, and a verified executable name.
  - Excluded the same-named headless service, used Linux pidfds to avoid PID-reuse races, and treated windows closing during refresh as normal. No service restart, OpenCode configuration change, custom app palette, Aether policy change, or wallpaper/theme switch was performed.
  - Installed the hook with `omarchy hook install theme-set` and deployed it and its helper through GNU Stow. Preserved unrelated unmanaged shell/bar/service files rather than adopting or overwriting them.

### Added
- **Refresh Safety Coverage and Gotcha**:
  - Added `tests/test_opencode_theme_refresh.py` with 11 isolated passing tests for process discovery, service/other-user exclusion, handler and PTY requirements, exit/reuse handling, hook dispatch, and actual signaling of a disposable test process.
  - Documented universal gotcha `17-opencode-exe-theme-refresh.md` and the helper/hook paths in the personalization references.

### Verification
- `python -B -m unittest discover -s tests -p 'test_opencode_theme_refresh.py' -v` (11 passing tests).
- `bash -n core/.config/omarchy/hooks/theme-set.d/20-opencode-system-refresh` and `git diff --check`.
- Reapplied the existing Foot colors and requested a refresh in both running OpenCode TUI windows; the original headless service remained alive. Verified OpenCode's palette cache matches the current foreground, background, and all 16 ANSI entries, while hashes of the system palette, generated Aether palette, and OpenCode configuration and the active wallpaper path remained unchanged.
- Follow-up acceptance: passively observed a user-selected **Appearance → Background** change within Aether. The same-theme generation changed, the native refresh hook/helper ran, and OpenCode's cached teal background changed to the new plum background in about 1.1 seconds, with all 16 ANSI entries matching. The user confirmed the visible window updated. No additional system, palette, or app configuration changes were made during this check.

## [2.19.0] - 2026-11-06
### Fixed
- **Dock-Style Checked Window Restore (`core/.local/bin/hypr-restore-window`, `core/.config/omarchy/plugins/jairo.minimized-windows/`)**:
  - Matched the floating dock's move operation and verified actual normal-workspace membership before focusing. Rejected or ineffective moves cannot fall through to focusing a still-minimized window.
  - Added checked process execution, plain-text error feedback, duplicate-restore suppression, and cleanup of the temporary animation override on failure. Only an already-visible minimized overlay is conditionally dismissed; the floating dock and system tray remain unchanged.
  - Clarified that the icon toggles only the list, while selecting a row restores just that window into the current workspace. Both surfaces share Omarchy's existing minimized pool.

### Added
- **Restore Regression Coverage and Documentation**:
  - Added helper tests plus real-QML offscreen mouse tests with mocked compositor data/actions, covering failed movement, stale windows, injection rejection, list-only icon toggling, selected-window dispatch, and plain-text title/error rendering.
  - Added universal gotcha `16-verify-minimized-restore-before-focus.md`, plugin usage documentation, and an updated shortcut description.

### Verification
- `python -B -m unittest discover -s tests -p 'test_minimized_restore.py' -v` (10 passing tests, including English/Arabic offscreen interaction cases).
- Original direct restore commands and the live popup row both returned approved disposable terminals to normal workspaces. The reported original overlay was not reproduced; this change enforces the restore invariant rather than claiming its precise cause was isolated.
- `bash -n core/.local/bin/hypr-restore-window`; checked helper restores passed with both tiled and explicitly floating disposable terminals, preserving existing window memberships and leaving no minimized overlay open. Loaded the clean plugin with `omarchy restart shell`; no widget-specific QML errors. `git diff --check` passed.

## [2.18.0] - 2026-11-06
### Fixed
- **Minimized-Windows Popup Opening (Universal Shell Recovery)**:
  - Restarted the shell with user approval after successful plugin rescans failed to load current diagnostic code. The user confirmed that the minimized-windows icon opened its popup afterward; logs recorded left-clicks and popup-open transitions.
  - Verified the actual widget with an isolated offscreen mouse test, then inspected live registration, enabled state, hit testing, and popup state. Full-bar offscreen testing was blocked by its compositor-dependent `PanelWindow` backend.
  - Removed temporary diagnostic code. No permanent widget, system-tray, layout, keybinding, package, or hardware configuration changes were needed.

### Added
- **Plugin Reload Verification Gotcha (`references/gotchas/15-shell-plugin-cached-reloads.md`)**:
  - Documented the observed stale-code behavior, the limits of an enabled-plugin check, and permission-gated shell recovery. The exact stale object behind the original missed click remains unconfirmed.

### Verification
- `omarchy restart shell`, live diagnostic IPC, and user-confirmed popup opening.
- Isolated Quickshell/QtTest mouse interaction with `QT_QPA_PLATFORM=offscreen` and `QT_FORCE_STDERR_LOGGING=1`.
- `git diff --check`; confirmed the temporary diagnostic IPC target is absent after the clean restart and the minimized widget remains visible with no widget-specific QML errors.

## [2.17.0] - 2026-11-06
### Added
- **Minimized Windows in Tiled Workspaces (`core/.local/bin/hypr-minimize-window`, `core/.config/omarchy/plugins/jairo.minimized-windows/`)**:
  - Rebound `SUPER + M` to move the active window to Omarchy's existing `special:minimized` workspace from either tiled or floating workspaces, while returning focus to its source workspace.
  - Added a universal bar icon next to the system tray. It appears while windows are minimized, lists their app/window titles, and restores a selected window to the focused monitor's active workspace.
  - Kept Omarchy's existing floating-workspace dock behavior intact; no packages or hardware-specific settings were added.

### Changed
- **Bar Layout (`core/.config/omarchy/shell.json`)**:
  - Added the minimized-windows widget beside the system tray.
- **Keyboard Shortcut Reference (`agents/.agents/skills/system-personalization/references/keybindings.md`)**:
  - Documented `SUPER + M` and the bar-based restore flow for tiled and floating workspaces.

### Verification
- `bash -n core/.local/bin/hypr-minimize-window` and a mocked `hyprctl` run confirmed the script tags, parks, and unfocuses the active window.
- `hyprctl configerrors && hyprctl reload && hyprctl configerrors` (clean after reload).
- `omarchy plugin list --json` confirms the widget is enabled; the Quickshell log had no errors loading this widget.
- Interactive minimize/restore on a live window remains for manual verification.

## [2.16.0] - 2026-11-06
### Added
- **Full GitHub Wallpaper Collection (`~/Pictures/Wallpapers/walls`)**:
  - Downloaded `JValdivia23/walls` using a shallow, no-tags clone without replacing any existing wallpaper folders. Indexed 1,642 supported static/previewable images, totaling 2.93 GiB of image data, and generated persistent 1536×864 thumbnails for every indexed image at low CPU priority.
  - Prepared the native carousel with 35 shuffled candidates plus the pinned current wallpaper. The indexed library and thumbnails remain outside the dotfiles repository.
- **Aether in Omarchy's Native Theme Menu**:
  - Upgraded the standalone `omarchy-aether` package to `0.2.0-1`. Its theme staging now supplies a normal `preview.png` showing the selected image and its ANSI palette.
  - Staged the generated theme at `~/.config/omarchy/themes/aether/` using a snowy-lake landscape from the downloaded repository. It is discoverable through **Omarchy → Appearance → Theme → Aether**, without opening the optional preview app or replacing the native Theme action.
  - The initial palette validated at 9.38:1 body contrast, at least 4.80:1 text contrast on tested surfaces, and 16 distinct ANSI colors. Tokyo Night was left active; no theme activation was performed during setup.

### Changed
- **Native Background Menu Routing (Universal User Setting)**:
  - Added `core/.config/omarchy-aether/menu.json`, deployed with GNU Stow, to declare `omarchy-aether background` as the desired native Background action.
  - Installed that action into the existing `~/.config/omarchy/extensions/omarchy-menu.jsonc` using `omarchy-aether integrate --yes`. The installer preserved comments/unrelated settings, retained the native row label/icon/aliases, and created a dated `before-aether` backup. The earlier Surface implementation and unrelated unmanaged Stow targets were not changed.
  - With Aether active, **Appearance → Background** uses its cached random subset and applies matching system colors. Other themes use the standard Omarchy selector/setter with their palettes unchanged. No keybinding, bar-plugin replacement, timer, or OpenCode-specific customization was installed.
- **Menu Compatibility Coverage**:
  - Added universal gotcha `14-omarchy-native-menu-overrides.md` for `appearance` vs. the `style` alias and metadata loss in action-only overrides.
  - Verified 43 passing Qt Test results, including the installed native JavaScript menu model, JSONC merge/backups, theme preview generation, static-theme fallback, and protection against a theme changing while the picker is open.

### Verification
- `git -C ~/Pictures/Wallpapers/walls status --short` (clean)
- Confirmed all 1,642 indexed thumbnail paths exist.
- `omarchy theme switcher --print-rows` includes exactly one Aether preview row; the native Theme action remains unchanged.
- `~/Projects/omarchy-aether/bin/test`, `omarchy theme current`, and `hyprctl configerrors`

## [2.14.0] - 2026-11-06
### Changed
- **Copilot Key Context Menu Binding (`core/.config/hypr/bindings-common.lua`)**:
  - Unbound Omarchy's default `SUPER + SHIFT + code:201` root menu shortcut (`{ menu = "root" }`) and rebound `SUPER + SHIFT + code:201` (the hardware chord emitted by the physical Copilot key: `Left Super + Left Shift + F23`) to `hl.dsp.send_shortcut({ mods = "", key = "Menu", window = "activewindow" })`, opening the native right-click context menu in the active window.
  - Resolved XKB keymap gotcha where enabling `altwin:menu_win` replaced `<COMP>` (`code:135`) with `Super_R`, removing `XKB_KEY_Menu` from the active `hl-virtual-keyboard-fcitx5` keymap and causing `hl.dsp.send_shortcut({ key = "Menu" })` to fail with `send_shortcut: key not found`. Kept `kb_options = "omarchy:shift_caps_compose"` and restarted `fcitx5 -r -d`.

### Verification
- `hyprctl reload && hyprctl configerrors`
- `hyprctl eval 'return hl.dispatch(hl.dsp.send_shortcut({ mods = "", key = "Menu", window = "activewindow" }))'` (`ok`)

## [2.13.0] - 2026-11-06
### Added
- **Standalone Omarchy Aether Palette Project (`~/Projects/omarchy-aether`)**:
  - Created and published the separate C++17 / Qt Quick application at [`JValdivia23/omarchy-aether`](https://github.com/JValdivia23/omarchy-aether), with qmake6, an Arch PKGBUILD, launcher integration, headless JSON commands, and an optional bundled agent skill. It keeps source, wallpapers, and personal dotfiles separate.
  - Installed `omarchy-aether 0.1.0-1` as **Aether Palette**, preserving the existing packaged `aether` executable and the earlier Surface-profile implementation.
  - Implemented Matugen extraction in dry-run mode, dark wallpaper-adaptive surfaces/accents, six distinct semantic color families, 16 unique ANSI entries, contrast validation, and bounded perceptual harmonization. Omarchy generates application themes from `colors.toml`; no OpenCode-specific configuration was changed.
  - Implemented the native Quickshell carousel protocol with cached 1536×864 previews, stable unique source aliases, 35-candidate shuffled batches, a pinned current wallpaper, and low-priority preparation after dismissal. No keybinding, menu override, timer, or automatic theme application was installed.
  - Verified 32 passing Qt Test results, including real-QML offscreen interaction, translated/RTL layouts, original-file preservation, cache identity, and native-shell failure handling. Twelve temporary sample wallpapers from `JValdivia23/walls` all passed, with body contrast 9.29–9.45:1, text contrast above 4.80:1 on tested surfaces, and 16 unique ANSI entries each.
- **Universal Aether Dependency (`core/packages.txt`)**:
  - Installed official Arch `matugen 4.2.0-1` through `omarchy pkg add matugen` and tracked it in `core/`, because wallpaper-driven theme generation is a general user feature rather than Surface-specific hardware configuration.
- **Universal Theme/Picker Gotchas**:
  - Added `11-aether-command-name-collision.md` and `12-native-wallpaper-picker-identity.md`, covering the existing Aether package identity, native basename deduplication, stable thumbnail cache keys, and preservation of images from replaceable theme directories.
  - Added `13-makepkg-stale-debug-archives.md` after a release rebuild reused an earlier split-debug archive. Disabled split-debug generation for the release, removed only the project's obsolete generated debug archive, and uninstalled its temporary debug package.

### Changed
- **Tokyo Night Established as the Visual Reference**:
  - Analyzed the user's selected Tokyo Night system palette: body contrast 8.10:1 and 16 unique ANSI entries, versus 9 unique entries in the modified Everforest terminal palette. Preserved Tokyo Night as the active theme throughout development; no compositor configuration, shortcuts, wallpapers, or application-specific settings were changed.

### Verification
- `pacman -Q matugen omarchy-aether aether`
- `~/Projects/omarchy-aether/bin/build` and `~/Projects/omarchy-aether/bin/test`
- `omarchy-aether --version`, `omarchy theme current`, and `hyprctl configerrors`

## [2.12.1] - 2026-11-06
### Fixed
- **OpenCode Sudo Dialog Language (`core/.config/opencode/vendor/opencode-sudo/`)**:
  - Added a local copy of the pinned upstream plugin with English dialogs, notifications, status labels, and server/helper errors to match the current OpenCode terminal interface.
  - Replaced the hard-coded `pt-BR` time formatter with the runtime's default locale. OpenCode 2.2.5's TUI API has no UI-language/translation API, so automatic language synchronization is unavailable.
  - Selected the actual source directory through `{env:HOME}/dotfiles/core/.config/opencode/vendor/opencode-sudo` so file-level Stow links cannot cause OpenCode's entrypoint containment check to omit the plugin.
  - Verified the local plugin is active with server/TUI/RPC components and both running terminal clients successfully reloaded it.
  - Documented upstream provenance, local changes, and update guidance in the plugin's `LOCAL.md`; added universal language and Stow deployment gotchas.

## [2.12.0] - 2026-11-06
### Added
- **OpenCode Sudo Password Cache (`core/.config/opencode/opencode.json`)**:
  - Installed the general-user OpenCode V2 plugin `maakhai/opencode-sudo`, pinned to commit `ec093cffd25472eec08f7097f2f53b62c10dd0cb`, using `opencode plugin add`.
  - Enabled its default masked TUI password prompt and 15-minute in-memory cache (`policy: on`, `ttl: 900`, password validation enabled, audit logging disabled).
  - `/sudo status` shows cache state; `/sudo lock` clears authentication; `/sudo ask` prompts for each command; `/sudo off` disables plugin-managed sudo.
  - Adopted the existing global OpenCode configuration into universal `core/` and linked it with GNU Stow. The pre-install configuration is backed up at `~/.config/opencode/opencode.json.before-sudo`.
  - Verified installation on OpenCode 2.2.5 with `opencode plugin list` and `/api/plugin`, which reports the plugin active with server, TUI, and RPC components.
  - Verified authentication with two successful `sudo id -u` calls (both returned `0`); plugin RPC status confirmed `cached: true`, no pending requests, and no authentication errors.

## [2.11.0] - 2026-11-04
### Added
- **ArtCraft Office & Document Suite (`core/packages.txt`)**:
  - Installed **WordCraft** (`wordcraft-bin` 0.15.1-1): Clean-room word processor alternative to Microsoft Word with `.docx`, `.odt`, `.rtf`, markdown, and PDF conversion, plus headless script execution and MCP server.
  - Installed **GridCraft** (`gridcraft-bin` 0.16.0-1): Clean-room spreadsheet alternative to Microsoft Excel with `.xlsx`/`.csv` conversion, formula calculation engine, headless execution, and MCP server.
  - Installed **DeckCraft** (`deckcraft-bin` 0.15.1-1): Clean-room presentation alternative to Microsoft PowerPoint with `.pptx` support, slide generation, headless rendering, and MCP server.
  - Installed **PdfCraft** (`pdfcraft-bin` 0.18.2-1): Native PDF workbench and Adobe Acrobat alternative with structure inspection, reading-order text extraction, page splitting/merging, redaction auditing, and MCP server.
  - Installed **Storytold Office** (`storytold-office` 1-1): AUR metapackage tying together the ArtCraft office application suite.
  - Installed and verified standalone CLI binaries: [`wordcraft-cli`](file:///usr/bin/wordcraft-cli), [`gridcraft-cli`](file:///usr/bin/gridcraft-cli), [`deckcraft-cli`](file:///usr/bin/deckcraft-cli), and [`pdfcraft-cli`](file:///usr/bin/pdfcraft-cli).
  - Tracked universal packages in `core/packages.txt`.

## [2.10.0] - 2026-11-04
### Changed
- **EdgePad Systemd User Service Bound to Graphical Session (`core/.config/systemd/user/edgepad.service`)**:
  - Bound unit to `graphical-session.target` (`After=graphical-session.target`, `PartOf=graphical-session.target`, `WantedBy=graphical-session.target`) rather than starting under early `default.target`.
  - Added explicit `Environment=OMARCHY_PATH=/usr/share/omarchy` to ensure Omarchy shell IPC commands function unconditionally.
  - Ensures EdgePad daemon inherits the active Wayland session environment (`WAYLAND_DISPLAY`, `HYPRLAND_INSTANCE_SIGNATURE`, `OMARCHY_PATH`).

### Fixed
- **EdgePad Volume & Brightness On-Screen Display (OSD) Pop-up Failure**:
  - Resolved issue where edgepad touchpad edge gestures adjusted volume and brightness levels silently without triggering the native Omarchy Quickshell OSD pop-up overlay.
  - Resolved `jq: parse error: Invalid numeric literal at line 1, column 28` caused by `omarchy-brightness-display` executing `hyprctl` before `HYPRLAND_INSTANCE_SIGNATURE` was accessible.
- **Gotcha Guide (`references/gotchas/08-edgepad-graphical-session-target.md`)**:
  - Documented EdgePad systemd target ordering, environment inheritance nuances, and OSD recovery steps.

## [2.9.0] - 2026-11-04
### Added
- **Omarchy Bar Widget Locking & Super-Drag Safety (`core/.config/omarchy/plugins/jairo.bar/Bar.qml`)**:
  - Cloned the built-in status bar into user plugin space (`jairo.bar`) using Omarchy's official plugin system.
  - Implemented bar locking mechanism respecting `"locked": true` in `shell.json`.
  - Guarded widget dragging behind the Super (`Qt.MetaModifier`) key: when the bar is locked, bare left-click dragging is completely disabled to eliminate accidental widget displacement on laptop touchpads.
  - Guarded widget removal ("poof" deletion) strictly behind `Super + drag`: widgets dragged off the bar can only be deleted if Super is held down, otherwise snapping safely back onto the bar without deletion.
- **Gotcha Guide (`references/gotchas/07-omarchy-bar-accidental-drag-removal.md`)**:
  - Documented accidental widget removal mechanics, distance thresholds, and resolution via `jairo.bar`.

### Fixed
- **Restored Lost CPU Vitals Widget (`core/.config/omarchy/shell.json`)**:
  - Re-added the missing `osesantos.vitals` CPU text monitor to the `left` section of the status bar.

## [2.8.0] - 2026-11-04
### Added
- **`oma-cast` Launcher Plugin for XPS Profile (`profiles/xps`)**:
  - Installed and enabled `typecraft.omacast` shell plugin via `omarchy plugin add https://github.com/typecraft-dev/oma-cast --enable --yes`.
  - Linked `omacast` CLI wrapper into `~/.local/bin/omacast` via `omacast install`.
  - Added safe dynamic loader `pcall(require, "hypr.omacast")` to master Hyprland configuration (`core/.config/hypr/hyprland.lua`).
  - Automated plugin installation, CLI linking, and symlink creation in the XPS profile setup script (`profiles/xps/setup.sh`).

### Changed
- **Rebound `oma-cast` to `Super + Space` (`profiles/xps/.config/hypr/omacast.lua`)**:
  - Rebound `SUPER + SPACE` from the default Omarchy root menu to `omacast launcher` (`hl.dsp.global("omacast:toggle")`), leaving `ALT + SPACE` to Omarchy's default dictation toggle (`omarchy-dictation toggle`).

## [2.7.0] - 2026-11-04
### Added
- **Ani-cli & Ani-cli-mx Core Anime Streaming Utilities (`core/packages.txt`)**:
  - Added `ani-cli` (v5.1-1) to universal core dotfiles packages for terminal anime search and playback via `mpv` and `fzf`.
  - Added `ani-cli-mx` (v3.0.10-1) to universal core dotfiles packages for Spanish/Mexico-oriented anime streaming (JKAnime, AnimeAV1, AniDB, AnimeX sources) with history tracking and auto-next support.
  - Installed both packages from the Arch User Repository (AUR) via `yay`.

## [2.6.0] - 2026-11-04
### Added
- **Rclone Cloud Storage Client for XPS Profile (`profiles/xps/packages.txt`)**: Scoped `rclone` (1.75.2) installation to the `xps` profile packages for Microsoft OneDrive files-on-demand virtual filesystem mounts.
- **Rclone OneDrive Files-on-Demand Systemd User Service (`profiles/xps/.config/systemd/user/onedrive.service`)**: Added background systemd user service in the `xps` profile mounting `onedrive:` to `~/OneDrive` with `--vfs-cache-mode full`, 15GB cache ceiling, 24h retention, and `fusermount3 -u -z` lazy unmount. Symlinked into `~/.config/systemd/user/onedrive.service`.
- **Microsoft 365 Drive Selection Gotcha Guide (`profiles/xps/gotchas/02-rclone-onedrive-business-drive-selection.md`)**: Documented SharePoint `PersonalCacheLibrary` vs primary document `OneDrive` drive selection quirk for institutional/business accounts.

### Fixed
- **OneDrive Root Directory Resolution (`~/.config/rclone/rclone.conf`)**: Corrected `drive_id` to point to the actual OneDrive document library rather than the default `PersonalCacheLibrary` (`WebPartCache`), exposing the user's full 416GB cloud document directory in `~/OneDrive`.

## [2.5.0] - 2026-10-31
### Added
- **EdgePad Core Touchpad Edge Gesture Daemon (`core/.config/edgepad/edgepad.toml`)**: Integrated `assembledev/edgepad` into core dotfiles, enabling continuous edge sliders and tap actions across laptops:
  - **Right Edge Slider**: Master Volume control (+/- 2% steps via `omarchy-audio-output-volume +2`/`-2` with native Omarchy OSD overlay).
  - **Right Edge Tap**: Toggle Audio Mute (`omarchy-audio-output-volume mute-toggle`).
  - **Left Edge Slider**: Display Brightness (+/- 5% steps via `omarchy-brightness-display +5%`/`5%-` with native Omarchy OSD overlay).
  - **Top & Bottom Edges**: Kept as passthrough (media gestures disabled) to prevent accidental triggers while navigating near edges.
- **EdgePad Systemd User Service (`core/.config/systemd/user/edgepad.service`)**: Created background user service that starts `edgepad daemon` on session login with minimal resource usage (~788 KB RAM, 0% idle CPU).
- **EdgePad Binary & Installer Automation (`install.sh`)**: Added automatic GitHub release binary downloader to `core/.local/bin/edgepad` and automated systemd user service enablement.
- **Touchpad Uaccess & Uinput Kernel Module Setup (`/etc/udev/rules.d/70-edgepad.rules` & `/etc/modules-load.d/uinput.conf`)**: Configured systemd-logind `uaccess` ACLs for `ID_INPUT_TOUCHPAD` devices and `/dev/uinput`, and configured `uinput` kernel module autoloading on boot.
- **Gotcha Guide (`references/gotchas/06-edgepad-uaccess-uinput.md`)**: Documented evdev uaccess ACL permissions, uinput module loading requirements, and `edgepad doctor` troubleshooting.

## [2.4.3] - 2026-10-31
### Added
- **`clinfo` diagnostic tool**: Installed via `pkexec pacman -S --needed clinfo` (`omarchy pkg add` needs an interactive sudo prompt, which doesn't work from a background shell). Used to query GPU compute units. It currently reports 0 OpenCL platforms because no ICD runtime (`intel-compute-runtime`) is installed. Not yet added to `core/packages.txt`.

## [2.4.2] - 2026-10-31
### Added
- **Omastorm Live Radar Shell Plugin for XPS Profile (`profiles/xps/setup.sh`)**: Added automated installation and enablement of `omastorm` (`com.omastorm.radar` from `https://github.com/wesleygrimes/omastorm.git`) in `profiles/xps/setup.sh`, providing real-time weather radar widgets and popovers in the status bar for the XPS profile.

## [2.4.1] - 2026-10-31
### Fixed
- **Restored Omarchy Status Bar Clock (`~/.config/omarchy/shell.json` & `core/.config/omarchy/shell.json`)**: Re-enabled `omarchy.clock` in the center section of the Quickshell status bar (`format = "dddd HH:mm"`, `formatAlt = "d MMMM 'W'ww yyyy"`, `verticalFormat = "HH\n—\nmm"`) after it was accidentally torn off the bar via drag-and-drop gesture. Synced active settings to core dotfiles.
- **Omarchy Vitals Sensors Panel & Suspend/Resume Crash Fix (`core/.config/omarchy/plugins/osesantos.vitals/`)**:
  - Replaced dynamic sensor model binding with static layout in `SensorsSource.qml` to prevent `quickshell` SIGSEGV in `QQmlInfo::~QQmlInfo` during suspend/resume cycles.
  - Redesigned `SensorsPanel.qml` into a scrolling list grouped by hardware chip with compact rows and thin temperature meters.
  - Updated `enumerate-sensors` script to sort naturally (e.g. `temp2` before `temp10`) and provide distinct labels for unlabelled sensors.

## [2.4.0] - 2026-10-31
### Added
- **Yazi Terminal File Manager in Core Dotfiles (`core/packages.txt`)**: Added `yazi` and `7zip` (for archive extraction and previews) to universal baseline packages in `core/packages.txt`. Installed on system via `pkexec pacman -S --needed yazi 7zip`.
- **Yazi Configuration (`core/.config/yazi/yazi.toml`)**: Created core Yazi configuration with 1:3:5 pane ratio, size linemode, directory-first sorting, preview settings, and editor integration using `omarchy-launch-editor --inline` and `xdg-open`. Symlinked to `~/.config/yazi/yazi.toml`.
- **Yazi Fish Shell Integration (`core/.config/fish/config.fish`)**: Added standard `y` shell wrapper function that launches `yazi` with `--cwd-file` and changes the active directory (`cd`) upon exit.
- **Yazi Desktop Launcher (`core/.local/share/applications/yazi.desktop`)**: Created desktop entry executing `omarchy-launch-tui yazi %u` with `inode/directory` MIME handling so Yazi appears in the Omarchy menu and application launcher. Symlinked to `~/.local/share/applications/yazi.desktop`.

### Fixed
- **Yazi 26+ Rule Syntax (`core/.config/yazi/yazi.toml`)**: Updated opener rules to use `[open.prepend_rules]` with valid `mime` and `url` matchers, replacing legacy `name = "*"` which caused strict schema validation parse errors on newer Yazi versions.

## [2.3.1] - 2026-10-29
### Added
- **Fullscreen Idle Inhibit Window Rule (`core/.config/hypr/hyprland.lua`)**: Added universal `o.window(".*", { idle_inhibit = "fullscreen" })` to inhibit idle, screensaver (150s), and DPMS screen sleep (300s) during fullscreen video playback (YouTube, media players, streaming services, games). Resolves an Omarchy upstream gap where `xdg-desktop-portal-gtk` fails to forward portal inhibit requests due to a missing `org.freedesktop.ScreenSaver` D-Bus provider. Documented in gotcha `05-omarchy-idle-inhibition-fullscreen.md`.

## [2.3.0] - 2026-10-29
### Removed
- **Unused `codex` Tool from `mise` (`core/.config/mise/config.toml`)**: Removed uninstalled `codex = "latest"` entry to eliminate 3-second GitHub version check timeouts and warnings during shell/agent initialization.

### Added
- **Ultra-Dark Everforest Theme Overlay for Dell XPS 13 (`profiles/xps/.config/omarchy/themes/everforest/colors.toml`)**: Added an Everforest palette overlay with high-contrast ultra-dark background (`#141719` vs stock `#2d353b`) calibrated specifically for the XPS 13 display, deepening terminal, bar, and application background surfaces while preserving original Everforest accents.
- **SideQuest Cross-Device Adaptation (`~/Projects/sidequest` & `profiles/xps/`)**:
  - Cloned `JValdivia23/sidequest` into `~/Projects/sidequest`.
  - Updated `is_touchscreen()` / `open_touchscreen()` in `lib/touch_mouse.py` to detect direct I2C HID touchscreens via kernel `INPUT_PROP_DIRECT` (`properties & 0x2`) in addition to `"touchscreen"` device name matching, enabling support for the XPS 13 (`LXST2024:00 1FD2:5010`) alongside Surface (`iptsd`).
  - Updated `recipes/dark-wanderer.sh` to dynamically apply `${DETECTED_RES_X}` and `${DETECTED_RES_Y}` (`2560x1600` on XPS, `3000x2000` on Surface) in `d2gl.ini`.
  - Configured `/etc/udev/rules.d/70-touchscreen-uaccess.rules` (`ENV{ID_INPUT_TOUCHSCREEN}=="1", TAG+="uaccess"`) and added idempotent setup to `profiles/xps/setup.sh` so the active seat user can open and grab `/dev/input/event5` without adding the user to the global `input` group.
  - Added automatic `.nomedia` creation in `$GAMES_ROOT/.nomedia` (`~/Games/.nomedia`) and `~/.minetest/.nomedia` in `install.sh` and `recipes/voxel-world.sh` so `localsearch-extractor-3` skips indexing internal game assets (preventing `libextract-mediainfo.so` crashes on `.mo3` tracker module audio files).
  - Updated `recipes/lawn-defense.sh` to detect when a pre-bundled `pvz-portable` binary inside `lawn-defense.enc` requires a higher CPU ISA level (`x86-64-v4` AVX-512 from Ice Lake / CachyOS) than the host CPU (`x86-64-v3` on Intel Wildcat Lake) and automatically recompile `pvz-portable` natively from source.
  - Installed SideQuest build and runtime prerequisites (`flatpak`, `clang`, `lld`, `cmake`, `ninja`, `python-pillow`, `luanti`) and provisioned all 6 catalog games.
- **Zen Profile Sync (`zen-sync`)**: Cloned `JValdivia23/zen-sync` to `~/zen-sync`, symlinked `~/.local/bin/zen-sync`, and restored encrypted Zen profile (workspaces, tabs, logins, extensions, and bookmarks) into `~/.config/zen`.
- **Zen Browser (`zen-browser-bin`)**: Installed official Omarchy package `zen-browser-bin` and added to `core/packages.txt`.
- **Dell XPS 13 (`xps`) Hardware Profile (`profiles/xps/`)**:
  - Created `profiles/xps/.config/hypr/monitors.lua` (`2560x1600@120Hz` at `scale = 1.25`, expanding viewport to `2048x1280`, plus `"auto"` fallback for external monitors).
  - Created `profiles/xps/.config/foot/foot.ini` (`font = JetBrainsMono Nerd Font:size=13`) to achieve the exact physical readability of the initial 2.0x setup.
  - Created `profiles/xps/.config/omarchy/shell.toml` (`[font] base-size = 13`) to scale Quickshell top bar and widgets strictly for XPS hardware.
  - Created `profiles/xps/.config/hypr/input.lua` (`natural_scroll = true`, `tap_to_click = true`, `clickfinger_behavior = true`, `scroll_factor = 0.4`, `drag_3fg = 0`, and 3/4-finger workspace/fullscreen/close gestures).
  - Created `profiles/xps/gotchas/01-xps-13-display-and-input.md` and `profiles/xps/gotchas/README.md` to store XPS-specific hardware progress and gotchas inside `profiles/xps/gotchas/`.
  - Updated `install.sh` and `init-skill.sh` to auto-detect Dell XPS hardware (`xps` profile).
- **Interactive Window Resize Mode (`SUPER + R`)**:
  - Ported the `resize` submap from `hyprland-dots` into `core/.config/hypr/bindings-common.lua` (supports Arrow keys, HJKL, `=` 50/50 split reset, and mouse/touch drag for tiled and floating windows).
- **Custom Webapp Icon & Desktop Database Sync**:
  - Ported XDG icon linking (`hicolor`, `pixmaps`, `gtk-update-icon-cache`) and `update-desktop-database` from `hyprland-dots` into `install.sh`.

### Changed
- **Dell XPS 13 Display & Font Scaling Calibrated to 1.25 (`profiles/xps/`)**: Updated `profiles/xps/.config/hypr/monitors.lua` to `scale = 1.25`, expanding logical resolution to an exact integer-grid `2048x1280`. Configured system interface font to `13` (`Adwaita Sans 13` in GTK and `base-size = 13` in `profiles/xps/.config/omarchy/shell.toml`) and calibrated foot terminal font to `JetBrainsMono Nerd Font:size=13` strictly in `profiles/xps/` without altering core dotfiles.
- **Default Web Browser Set to Zen (`zen.desktop`)**: Switched default web browser and XDG MIME handlers (`text/html`, `http`, `https`, `about`, `unknown`) from Chromium to Zen Browser using `omarchy default browser zen`. Configured Firefox Wayland support in `~/.config/environment.d/omarchy-firefox-wayland.conf`.
- **Isolated Surface & Aether Dynamic Theme Components into `profiles/surface/`**:
  - Moved Aether dynamic theme files (`themes/aether`, `hooks/theme-set.d/aether-dynamic.sh`, `extensions/omarchy-menu.jsonc`, `omarchy-aether-cycler.{service,timer}`, `.local/bin/omarchy` wrapper, `omarchy-precache-fast`, and `omarchy-theme-*` scripts) plus `jmvp.power`, `jmvp.background`, `foot/foot.ini`, `defaults/agent`, `lichess`, `mac-key-helper`, and `Andahuaylas*.jpg` from `core/` into `profiles/surface/`.
  - Moved `matugen` from `core/packages.txt` to `profiles/surface/packages.txt`.
- **Updated `core/.config/omarchy/shell.json` to Omarchy 4.5 Schema**:
  - Preserved `osesantos.vitals` (`cpu`, `memory`, `sensors`) in the top-left bar while adopting Omarchy 4.5's bottom `dock`, `centerBegin`/`centerEnd` (`omarchy.elsewhen`), and stock `omarchy.power` / `omarchy.background`.

### Fixed
- **Preserved `omarchy:shift_caps_compose` in `hypr-toggle-altwin`**:
  - Updated `core/.local/bin/hypr-toggle-altwin` so toggling `altwin:swap_lalt_lwin` retains Omarchy's `omarchy:shift_caps_compose` XKB option.
- **Polkit (`pkexec`) Fallback in `install.sh`**:
  - Added automatic `pkexec` fallback in `install_packages_list` when `install.sh` runs without an interactive TTY.

## [2.2.18] - 2026-09-15
### Removed
- **Waypaper & Unused Dependencies Purged**:
  - Uninstalled `waypaper` from AUR and removed 17 unused/orphaned Python runtime and build packages (`python-screeninfo`, `python-imageio`, `python-imageio-ffmpeg`, `python-numpy`, `python-pillow`, `python-setuptools`, `python-platformdirs`, `python-wheel`, `python-build`, `python-installer`, `python-pyproject-hooks`, `python-jaraco.*`, `python-autocommand`, `python-more-itertools`), freeing ~60 MB.
  - Purged obsolete `core/.config/waypaper/` directory and unlinked `~/.config/waypaper`.
  - Deleted legacy dummy stub script `core/.local/bin/hyprpaper` and unlinked `~/.local/bin/hyprpaper`.
  - Removed `waypaper` entry from `core/packages.txt`.

### Changed
- **Synchronized Documentation & Tooling Prompts**:
  - Updated `core/.local/bin/omarchy-sync-wallpapers` completion hint to reference `ALT + SPACE` instead of `waypaper`.
  - Updated `references/keybindings.md` documentation for `ALT + Space` to describe the native Omarchy Quickshell carousel and dynamic palette setter.

## [2.2.17] - 2026-09-13
### Added
- **macOS-Style Text Selection & Deletion Keybindings (`bindings-common.lua`)**:
  - Bound `SUPER + SHIFT + LEFT` / `RIGHT` to instant line selection (`SHIFT + Home` / `SHIFT + End`).
  - Bound `SUPER + SHIFT + UP` / `DOWN` to document selection (`CTRL + SHIFT + Home` / `CTRL + SHIFT + End`).
  - Bound `ALT + Delete` to forward word deletion (`CTRL + Delete`).
  - Bound `SUPER + Delete` to forward line deletion (`CTRL + K` in terminal, `SHIFT + End + BackSpace` in GUI).
- **Surface Book 3 Hardware Utility Scripts (`profiles/surface/.local/bin/`)**:
  - Created `surface-rotate`: Instant display rotation utility using `jq` to cycle `eDP-1` transform (0° -> 90° -> 270° -> 0°).
  - Created `surface-detach`: Tablet latch release helper invoking `surface dtx request` with desktop notification feedback.

### Changed
- **Resolved Window Swap vs macOS Text Selection Conflict**:
  - Unbound default `SUPER + SHIFT + ARROWS` from window swapping, eliminating accidental window tile reordering when selecting text.
  - Rebound window swapping to `CTRL + SHIFT + ARROWS` (naturally complementing `CTRL + ARROWS` for window focus navigation).
- **Cleaned Surface Profile Keybindings (`bindings-profile.lua`)**:
  - Replaced inline subshell and Python string escaping for `SUPER + D` and `SUPER + R` with direct calls to `surface-detach` and `surface-rotate`.

## [2.2.16] - 2026-09-13
### Fixed
- **Foot Terminal Missing Theme Resolution (`theme/foot.ini`)**:
  - Isolated root cause of `error: foot: foot.ini:3: [main].include: ~/.local/state/omarchy/current/theme/foot.ini: failed to open: No such file or directory`.
  - Upstream `omarchy-theme-set` copies user themes with `cp -r` without dereferencing (`-L`). When `~/.config/omarchy/themes/aether/colors.toml` was managed as a GNU Stow relative symlink (`../../../../dotfiles/...`), `cp -r` copied it into `~/.local/state/omarchy/current/next-theme/` (5 directory levels deep instead of 4), pointing to non-existent `~/.local/dotfiles/...`.
  - Because `colors.toml` was a broken link in `next-theme`, `omarchy-theme-set-templates` skipped compiling dynamic templates, leaving `foot.ini`, `alacritty.toml`, and other terminal configs missing.
  - Renamed `core/.config/omarchy/themes/aether/colors.toml` to `colors.toml.seed` in dotfiles, untracked runtime `colors.toml` from GNU Stow, and restored atomic `mv "$TMP_TOML" "$THEME_DIR/colors.toml"` in `omarchy-theme-dynamic-update` to guarantee `colors.toml` is always a regular file.
  - Added post-install step in `install.sh` to seed `colors.toml` as a regular file and ensure `foot.ini` is compiled.
  - Re-compiled active theme templates, verifying `foot --check-config` exits cleanly with zero errors.

## [2.2.15] - 2026-09-13
### Added
- **GitHub Wallpaper Library & Fast Sync Tooling**:
  - Forked full 3.3 GB wallpaper library (`1,500+` curated images across abstract, anime, calm, gruvbox, nature, stalenhag, etc.) to GitHub profile at [`JValdivia23/walls`](https://github.com/JValdivia23/walls).
  - Tracked default personalized wallpapers ([`Andahuaylas_16x9.jpg`](core/Pictures/Wallpapers/Andahuaylas_16x9.jpg), [`Andahuaylas.jpg`](core/Pictures/Wallpapers/Andahuaylas.jpg)) directly inside `core/Pictures/Wallpapers/` so that fresh installations immediately boot with the active default wallpaper without waiting for large downloads.
  - Added [`core/.local/bin/omarchy-sync-wallpapers`](core/.local/bin/omarchy-sync-wallpapers) utility: performs high-speed shallow clone (`--depth 1`) from `JValdivia23/walls` (with automatic fallback to upstream `dharmx/walls`), with idempotency, update support, and non-destructive conflict detection.
  - Integrated wallpaper status check into `install.sh` post-install and completion summaries.

### Fixed
- **Fresh Installation & Package Resolution Hardening**:
  - Rewrote `install_packages_list` in [`install.sh`](install.sh) to query `pacman -Si` for each package: official Arch/Omarchy repository packages install via `omarchy pkg add` / `pacman -S`, while AUR packages (`waypaper`, `brave-origin-bin`, `surface-dtx-daemon-bin`, `surface-control-bin`) route cleanly through `omarchy pkg aur add` or `yay -S`, preventing package manager abortions on fresh systems.
  - Added `python` to [`core/packages.txt`](core/packages.txt) to guarantee `init-skill.sh` and Hyprland display rotation utilities run out-of-the-box on minimal Arch base installs.
  - Hardened GPG key retrieval in [`profiles/surface/pre-install.sh`](profiles/surface/pre-install.sh) with `--connect-timeout 10 --retry 3`.
  - Added `sudo limine-update || true` in [`profiles/surface/setup.sh`](profiles/surface/setup.sh) so that `/etc/limine-entry-tool.d/zz-surface-kernel.conf` takes effect immediately on new installations before the initial reboot.
  - Added `pre-install.sh` to Stow ignore flags, directory sanitizers, and conflict checkers across `install.sh`.
  - Fixed `omarchy-theme-dynamic-update` to update `colors.toml` in-place (`cat > ... && rm`) rather than replacing the inode with `mv`, preserving the GNU Stow symlink back to the dotfiles repository.
  - Guaranteed `~/.bashrc` exists before checking or appending the interactive Fish auto-launch guard.
  - **Hyprland Inotify & Symlink Preservation**: Fixed `check_and_backup_path` in `install.sh` to preserve existing relative Stow symlinks. Previously, removing valid symlinks during conflict scanning caused Hyprland's inotify watcher to attempt parsing during the millisecond `hyprland.lua` was unlinked, triggering a transient `cannot open /home/jmvp/.config/hypr/hyprland.lua: No such file or directory` error.
  - **Automated Hyprland Post-Install Reload**: Added automatic `hyprctl reload` during post-install step when Hyprland is active.
  - **Limine Bootloader Idempotency**: Configured `profiles/surface/setup.sh` to verify existing `zz-surface-kernel.conf` before invoking `sudo`, preventing unnecessary password prompt stalls during non-interactive runs.

## [2.2.14] - 2026-09-13
### Added
- **Surface Profile Pre-Install Hook (`profiles/surface/pre-install.sh`)**:
  - Automatically imports and locally signs the Linux-Surface GPG repository key (`56C464BAAC421453`).
  - Idempotently adds `[linux-surface]` repository block to `/etc/pacman.conf` and refreshes databases (`pacman -Sy`), ensuring Surface kernel and drivers resolve seamlessly during fresh installs.
- **Surface Profile Packages Expansion**:
  - Added `linux-surface`, `linux-surface-headers`, `surface-control-bin`, and `fcitx5` Wayland virtual keyboard suite (`fcitx5`, `fcitx5-gtk`, `fcitx5-qt`) to `profiles/surface/packages.txt`.
- **Core Packages & Tooling Expansion**:
  - Added `matugen` (M3 palette extraction), `waypaper`, `jq`, `mise-bin`, and `brave-origin-bin` to `core/packages.txt`.
- **Omarchy Shell & Plugins Version Tracking**:
  - Tracked Omarchy status bar layout [`core/.config/omarchy/shell.json`](core/.config/omarchy/shell.json) including telemetry widgets, custom clock, and panel configuration.
  - Tracked custom plugins [`jmvp.power`](core/.config/omarchy/plugins/jmvp.power/) and [`osesantos.vitals`](core/.config/omarchy/plugins/osesantos.vitals/) with wallpaper-adaptive foreground charts.
  - Tracked default coding agent [`core/.config/omarchy/defaults/agent`](core/.config/omarchy/defaults/agent) (`agy`).
  - Tracked initial dynamic theme definition [`core/.config/omarchy/themes/aether/colors.toml`](core/.config/omarchy/themes/aether/colors.toml) and hook [`core/.config/omarchy/hooks/theme-set.d/aether-dynamic.sh`](core/.config/omarchy/hooks/theme-set.d/aether-dynamic.sh).
  - Tracked tool version definitions in [`core/.config/mise/config.toml`](core/.config/mise/config.toml).
- **WebApps, Desktop Launchers & Icons Tracking**:
  - Tracked FreeDesktop application entries in `core/.local/share/applications/` (`YouTube.desktop`, `AllAnime.desktop`, `Hanime.desktop`, `PH.desktop`, `XH.desktop`, `org.lichess.mobile.desktop`) with spec-compliant quoting.
  - Tracked application icons in `core/.local/share/applications/icons/` and `core/.local/share/icons/hicolor/256x256/apps/lichess.png`.
  - Added portable wrappers in `core/.local/bin/` (`lichess`, `xh-launch`, `omarchy-precache-fast`).
- **Automated User Timers & Fish Shell Guard**:
  - Added post-install step to `install.sh` reloading user systemd daemon and enabling `omarchy-aether-cycler.timer`.
  - Added post-install step to `install.sh` ensuring interactive Fish auto-launch guard is appended to `~/.bashrc`.

### Fixed
- **Path Portability Hardening**:
  - Replaced all hardcoded `/home/jmvp/` paths across `bindings-common.lua`, `omarchy-menu.jsonc`, `Background.qml`, `omarchy-theme-bg-set`, `omarchy-theme-dynamic-update`, `omarchy-theme-hourly-cycle`, `omarchy`, and `waypaper/config.ini` with dynamic `$HOME` resolution.
- **GNU Stow Conflict Resolution**:
  - Updated `check_and_backup_path` in `install.sh` to automatically clean up pre-existing manual absolute symlinks pointing into `$DOTFILES_DIR` before running Stow, eliminating "existing target is not owned by stow" conflicts.

## [2.2.13] - 2026-09-13
### Added
- **Surface Kernel Limine Boot Priority Drop-In**:
  - Configured `/etc/limine-entry-tool.d/zz-surface-kernel.conf` to set `BOOT_ORDER="linux-surface*, *, *fallback, Snapshots"`, making `linux-surface` the default boot option upon reboot.
  - Preserved stock Arch `linux` as a secondary fallback entry beneath `linux-surface`.
  - Added modular gotcha [`profiles/surface/gotchas/09-surface-kernel-limine-boot-default.md`](../profiles/surface/gotchas/09-surface-kernel-limine-boot-default.md) and linked it in [`references/gotchas/INDEX.md`](gotchas/INDEX.md).
  - Integrated Limine drop-in creation into `profiles/surface/setup.sh` for reproducible setup across installations.

## [2.2.12] - 2026-09-12
### Fixed
- **Surface Book 3 USB-C Charging Deadlock & Power Delivery Flapping**:
  - Diagnosed USB-C port failure triggered after disconnecting an alternate-mode display accessory (XREAL Air 2 Pro) that threw continuous xHCI bandwidth allocation errors (`-28`).
  - Identified base Power Delivery PHY controller deadlock causing 0V detection ($R_d$ pull-down failure on CC lines), resolved via DTX clipboard detachment hardware cold reboot.
  - Isolated secondary ~350ms power negotiation flapping loop on Apple 61W USB-C adapter (Model A1718): identified missing 15V rail and 3.0A Over-Current Protection (OCP) trip when attempting to fast-charge dual depleted batteries (`BAT1` and `BAT2` < 20%) while system is active (~65W–75W peak load).
  - Documented root causes, sleep/suspend charge bypass, and hardware requirements in [`profiles/surface/gotchas/08-surface-book-usb-c-charging-quirks.md`](../profiles/surface/gotchas/08-surface-book-usb-c-charging-quirks.md).

## [2.2.11] - 2026-09-12
### Added
- **Lichess Client Local Build & Desktop Integration**:
  - Forked official Flutter client (`lichess-org/mobile`) to GitHub user account (`JValdivia23/mobile`) and cloned into `~/Work/lichess-mobile`.
  - Installed build toolchain prerequisites: `cmake` and `ninja` via `pacman`, and `flutter` (v3.47.3 matching repo constraints) via `mise`.
  - Initialized dependencies and executed code generation (`dart run build_runner build`).
  - Compiled native Linux release bundle (`build/linux/x64/release/bundle/lichess_mobile`).
  - Configured production endpoints: set default hosts to `lichess.org` and `socket.lichess.org` in `lib/src/constants.dart` (resolving offline status caused by upstream dev default `lichess.dev`).
  - Added native Linux audio fallback in `lib/src/model/common/service/sound_service.dart` using PipeWire (`pw-play`) and PulseAudio (`paplay`), enabling low-latency sound effects on Linux desktop (upstream `sound_effect` plugin only supports Android and iOS; submitted upstream as PR [#3670](https://github.com/lichess-org/mobile/pull/3670)).
  - Created wrapper executable in `~/.local/bin/lichess` and registered FreeDesktop launcher in `~/.local/share/applications/org.lichess.mobile.desktop` with high-resolution Lichess icon.

## [2.2.10] - 2026-09-12
### Fixed
- **Vibrant Subject Color Extraction Over Dark Background Shadows**: Resolved issue where wallpapers featuring vivid focal subjects against large dark or night backgrounds (such as `a_car_on_fire_at_night.jpg`) extracted cold cyan/blue colors. Matugen's `--source-color-index 0` was hardcoded to pick the largest pixel cluster, which was the dark night sky shadow (`#0a191c`) rather than the blazing fire (`#e52c2a`).
- **Saturation-Aware Preference**: Updated `omarchy-theme-extract-palette` to use `--prefer saturation`, ensuring Material You selects the rich, eye-catching subject of the image (fire reds/oranges, flower pinks, sunset ambers) rather than background noise.

## [2.2.9] - 2026-09-12
### Fixed
- **Hourly Carousel Pool Shuffle & Oneshot Systemd Lifecycle**: Resolved bug where wallpapers in the `ALT + SPACE` carousel never refreshed and showed the same figures from the previous day. Because `omarchy-aether-cycler.service` is a `Type=oneshot` systemd service, background jobs spawned with `&` inside the script were immediately killed by systemd cgroup cleanup before completing.
- **Synchronous Service Execution**: Updated `omarchy-theme-hourly-cycle` to execute `omarchy-theme-shuffle-backgrounds` and `omarchy-theme-dynamic-update` synchronously in foreground so systemd waits for the complete shuffle and recolor (~10s).
- **Theme Background Accumulation Fix**: Prevented `omarchy-theme-dynamic-update` from endlessly accumulating past wallpapers in `~/.config/omarchy/themes/aether/backgrounds/`. Cleared stale symlinks so `ALT + SPACE` displays only the active wallpaper and the fresh 35 shuffled pool figures.
- **Increased Carousel Pool**: Bumped random wallpaper pool in `omarchy-theme-shuffle-backgrounds` from 24 to 35 pictures.

## [2.2.8] - 2026-09-11
### Fixed
- **Dynamic Theme Color Switching Across Desktop Menus & Shortcuts**: Resolved root-cause issue where choosing wallpapers via Omarchy menu (`SUPER + SPACE` -> Background), native Quickshell carousel (`ALT + SPACE`), or desktop double-click executed stock `/usr/bin/omarchy-theme-bg-set` due to Omarchy's system-first PATH precedence in non-interactive subshells.
- **Explicit Executable Dispatch**:
  - Updated `ALT + SPACE` in `core/.config/hypr/bindings-common.lua` to invoke `/home/jmvp/.local/bin/omarchy-theme-bg-set` directly.
  - Overrode `style.background` in `~/.config/omarchy/extensions/omarchy-menu.jsonc` (tracked in `core/.config/omarchy/extensions/`) to call `/home/jmvp/.local/bin/omarchy-theme-bg-set`.
  - Cloned `omarchy.background` to `jmvp.background` via `omarchy plugin clone` and patched `Background.qml` to invoke the custom setter.
  - Added Omarchy CLI wrapper in `core/.local/bin/omarchy` intercepting `theme bg set` commands.
- **Process Decoupling & Non-Blocking Response**: Hardened `omarchy-theme-bg-set` with `nohup ... &` and user-state logging (`~/.local/state/omarchy/dynamic-theme.log`), decoupling background palette extraction (~1.9s) and theme staging (~4s) from the caller so wallpaper switching and picker modal close remain instant (< 10ms).
- **Environment PATH Hardening**: Configured `~/.config/environment.d/10-user-bin.conf` and updated `~/.bashrc` to prepend `~/.local/bin` ahead of system directories.

## [2.2.7] - 2026-09-11
### Added
- **All-Native Quickshell Wallpaper Picker**: Eliminated external Waypaper GUI overhead and integrated directly with Omarchy's native Quickshell carousel. Bound `ALT + SPACE` directly to the native background switcher (`omarchy-theme-bg-switcher`).
- **Shuffled Wallpaper Pool & Instant Pre-Caching**: Implemented `omarchy-theme-shuffle-backgrounds` in `core/.local/bin/` to randomly sample 35 diverse wallpapers from the 1,600+ collection into `~/.config/omarchy/backgrounds/aether/`. Pre-cached thumbnails reduce picker open latency to under 40ms.
- **Hourly Dynamic Wallpaper & Palette Cycler**: Created systemd user timer and service (`omarchy-aether-cycler.timer` / `.service`) running hourly. When `aether` theme is active, it automatically selects a fresh wallpaper from the 1,600+ collection, smoothly crossfades the desktop, extracts Material You M3 colors via `matugen`, live-recolors terminals and Quickshell, and rotates the carousel pool. Skips completely when any static theme is active.
- **Background Low-Priority Thumbnail Pre-Cacher**: Deployed `omarchy-theme-precache-all-wallpapers` in the background with `nice -n 19` to progressively generate thumbnails for all 1,647 wallpapers.

## [2.2.6] - 2026-09-11
### Fixed

- **Omarchy Vitals Status Bar Color Alignment (`osesantos.vitals`)**: Fixed color mismatch between Vitals widgets and native Omarchy bar widgets. Replaced static `bar.foreground` with dynamic `bar.barForeground` across `charts/*.qml` (`Text`, `Mini`, `Line`, `Bars`, `Pie`, `Fill`, `Speed`), allowing Vitals to inherit the exact wallpaper-adaptive contrast foreground (`transparentForeground`) and smooth color transition animations used by all other icons on the bar.

## [2.2.5] - 2026-09-11
### Added
- **Dynamic Material You Theme (`aether`)**: Created dedicated dynamic theme in `~/.config/omarchy/themes/aether/` powered by `matugen` (Material Design 3 tonal-spot palette extraction).
- **Theme-Aware Wallpaper Setter (`omarchy-theme-bg-set`)**: Added unified wrapper in `~/.local/bin/omarchy-theme-bg-set` (tracked in `~/dotfiles/core/.local/bin/`). When theme is `aether`, wallpaper changes dynamically extract colors and live-recolor Omarchy Quickshell, Foot terminals (via OSC escape codes), Hyprland window borders, btop, and desktop apps. When any static theme is active (Catppuccin, Tokyo Night, etc.), wallpaper changes keep theme colors 100% stable.
- **Waypaper GUI & Shortcut (`ALT + Space`)**: Installed `waypaper` from AUR and configured `~/.config/waypaper/config.ini` with `post_command = omarchy-theme-bg-set "$wallpaper"`. Bound `ALT + Space` in `core/.config/hypr/bindings-common.lua` and added centered floating window rule (`65% x 75%`) in `core/.config/hypr/hyprland.lua`.
- **Complete Wallpaper Collection**: Synced full 3.47 GB `dharmx-walls` library from laptop `cachyos-cu` (`10.0.0.8`) into `~/Pictures/Wallpapers/` alongside local high-res `Aether` (2K–8K dark/light) collection.

## [2.2.4] - 2026-09-11
### Added

- **Omarchy Vitals Status Bar Plugin (`osesantos.vitals`)**: Installed verified community plugin from `https://github.com/osesantos/omarchy-vitals.git` into `~/.config/omarchy/plugins/osesantos.vitals`.
- **System Telemetry Widgets on Status Bar**: Configured three modular Vitals entries in the `left` section of `~/.config/omarchy/shell.json` after Workspaces:
  - **CPU**: `module: "cpu"`, `widget: "text"` (`󰻠` usage %)
  - **RAM**: `module: "memory"`, `widget: "text"` (`󰍛` usage %)
  - **Temperature**: `module: "sensors"`, `widget: "text"` (`󰔏` package temp in °C from hwmon coretemp)

## [2.2.3] - 2026-09-11
### Changed
- **Migrated to `omarchy-dev` Channel**: Upgraded Omarchy from `omarchy 4.0.3-1` to `omarchy-dev 4.0.0.r1832.g23dab9e-1` and `omarchy-settings-dev` (tracking the upstream `quattro` development branch tip).
- **Default Coding Agent Switched to Antigravity (`agy`)**: Executed Omarchy migration `1786719479.sh`, automatically transitioning default coding agent from legacy `gemini` to Google Antigravity (`agy` 1.2.1) in `~/.config/omarchy/defaults/agent`. Linked Omarchy skills to `~/.gemini/config/skills/` (`omarchy`, `diagnose-crash`), and purged dead Gemini CLI wrapper. Verified `omarchy-agent` launches `agy --dangerously-skip-permissions`.

## [2.2.2] - 2026-09-11
### Added
- **CachyOS-Style Terminal Autosuggestions**: Installed and configured `fish` and `omarchy-fish` (`omarchy/omarchy-fish`). Added Fish shell configuration in `core/.config/fish/config.fish` with `fish_default_key_bindings` (enabling standard emacs line navigation and CachyOS-style autosuggestion completion with `Right Arrow` and `Ctrl+F`), muted gray suggestions (`fish_color_autosuggestion`), Starship prompt, and user `~/.local/bin` PATH integration.
- **Foot Shell Configuration**: Configured `shell=/usr/bin/fish` in `core/.config/foot/foot.ini` so Foot terminal launches Fish directly without intermediate wrapper overhead.
- **Interactive Bash Auto-Launch Guard**: Configured a non-destructive auto-launch guard in `~/.bashrc` that transitions interactive user shells into Fish while preserving standard Bash for scripts, cron, and `-c` one-liners.
- **Universal Gotcha 04**: Authored [`04-omarchy-fish-quattro-integration.md`](gotchas/04-omarchy-fish-quattro-integration.md) documenting Omarchy Quattro environment compatibility and avoiding upstream `omarchy-setup-fish` script overwrites.
- **Core Packages Tracking**: Added `fish` and `omarchy-fish` to `core/packages.txt`.

## [2.2.1] - 2026-09-11
### Added
- **Cursor Inactivity Timeout**: Configured `cursor:inactive_timeout = 3` in `core/.config/hypr/hyprland.lua`. Automatically hides the mouse cursor after 3 seconds of inactivity while watching videos, browsing, or reading across all machine profiles. Cursor immediately reappears upon mouse or touchpad movement.

## [2.2.0] - 2026-09-10
### Removed
- **Legacy Root Directories Purged**: Deleted 15 legacy CachyOS / Noctalia folders from repository root: `alacritty/`, `bin/`, `btop/`, `fish/`, `gtk/`, `hypr/`, `kitty/`, `niri/`, `noctalia/`, `packages/`, `scripts/`, `swayimg/`, `waypaper/`, `webapps/`, and `zigoku/`.
- **ASUS ROG Purged**: Removed `profiles/asus-rog/` entirely and purged `05-asus-supergfxctl-hybrid.md`. Stripped all ASUS hardware references from `install.sh`, `AGENTS.md`, `README.md`, `snapshot.sh`, and `init-skill.sh`.
- **Redundant Core Settings Removed**: Purged `core/.config/hypr/looknfeel.lua` and old Noctalia configs (`alacritty/`, `btop/`, `fish/`, `kitty/`) from `core/`. Omarchy Quattro defaults in `/usr/share/omarchy/default/` now handle decorations, animations, themes, and windows cleanly.
- **Redundant Binds Cleaned**: Removed redundant YouTube launcher from `core/.config/hypr/bindings-common.lua`.
- **Legacy Gotchas Removed**: Removed `08-localsend-ufw-firewall.md` and `09-kitty-ssh-terminfo.md`.

### Added
- **Authoring Guide**: Created [`HOW_TO_WRITE_A_GOTCHA.md`](gotchas/HOW_TO_WRITE_A_GOTCHA.md) establishing clear rules and procedures for writing modular gotchas on fresh systems.
- **Hardware Profile Gotchas Architecture**: Moved Surface-specific gotchas (`03-surface-scaling-and-touch.md`, `04-surface-dtx-tablet-detach.md`, `07-fcitx5-wayland-virtual-keyboard.md`) to `profiles/surface/gotchas/`.
- **Dynamic Gotcha Symlinking**: Updated `install.sh` to automatically symlink `profiles/<profile>/gotchas/*` into `~/.agents/skills/system-personalization/references/gotchas/` during setup.

### Changed
- **Renumbered Elevated Prompts Gotcha**: Promoted universal sudo password wrapper to `03-elevated-password-prompts.md`.
- **Clean INDEX.md**: Streamlined `references/gotchas/INDEX.md` to link only universal guardrails (`01-hyprland-lua-validation.md`, `02-omarchy-read-only-safety.md`, `03-elevated-password-prompts.md`, and `HOW_TO_WRITE_A_GOTCHA.md`).
- **Streamlined Packages**: Simplified `core/packages.txt` to only essential tools not bundled by Omarchy (`stow`, `ripgrep`, `fd`, `wl-clipboard`, `fastfetch`, `starship`).

## [2.1.2] - 2026-09-10
### Fixed
- **FreeDesktop Desktop Entry Compliance**: Fixed `.desktop` file syntax in webapps to strictly adhere to Desktop Entry Specification.
- Verified 100% compliance with `desktop-file-validate` across all repository desktop files.

## [2.1.1] - 2026-09-10
### Fixed
- Hardened Omarchy Quattro Master Installer ([`install.sh`](file:///home/jmvp/dotfiles/install.sh)):
  - **Non-Destructive Backup Protection**: Added canonical path resolution (`realpath -q`) to ensure files and symlinks resolving inside `$DOTFILES_DIR` are never treated as conflicting paths or moved to backup.
  - **Directory Symlink Sanitization**: Implemented `sanitize_directory_symlinks` to safely convert any pre-existing package directory symlinks into regular directories, preventing GNU Stow `--no-folding` conflicts and `ln: ... are the same file` fallback errors.
  - **Conflicting Symlink Backup**: Updated conflict scanner to inspect existing symlinks pointing outside the dotfiles repository, moving them to `$BACKUP_DIR` so GNU Stow can link without aborting.
  - **Idempotent Fallback Linking**: Enhanced `link_dir_files` fallback to detect already linked targets and avoid redundant work.
  - **Bytecode Cache Filtering**: Added `__pycache__` and `\.pyc$` ignore filters across `install.sh` and all package `.stow-local-ignore` files.
  - **Dry-Run Output Clarity**: Explicitly prefixed simulated backup actions (`[dry-run] [Backup]`) and labeled `Simulated Backup: <dir>` in final summary.

- Implemented Omarchy Quattro Master Installation Orchestrator ([`install.sh`](file:///home/jmvp/dotfiles/install.sh)):
  - Strict mode execution (`set -euo pipefail`) with full CLI argument parser (`--profile`, `--profiles`, `--dry-run`, `--only-stow`, `--only-packages`, `--help`).
  - Automated hardware detection engine probing `/sys/class/dmi/id/` (product name, vendor, chassis type), `lspci`, and kernel to identify machine profile (`surface` or `desktop`) and hardware traits (`laptop`).
  - Non-destructive backup handler: automatically backs up conflicting non-symlink configuration files in `~/.config/` or `~/.local/bin/` to `~/.dotfiles_backup_<timestamp>/`.
  - Package synchronization using `omarchy pkg add` with `pacman -S --needed` fallbacks for `core/packages.txt` and active profile packages.
  - Deployment using GNU Stow with `--no-folding` and ignore filters, plus direct symlink linking fallback.
  - Post-installation execution of profile `setup.sh` and initialization of the `system-personalization` skill via `init-skill.sh --profiles "$ACTIVE_PROFILES"`.
- Implemented comprehensive repository architecture documentation in [`AGENTS.md`](file:///home/jmvp/dotfiles/AGENTS.md):
  - 3-Tier repository architecture guide (`core/`, `profiles/`, `agents/`).
  - Omarchy Quattro safety rules (read-only `/usr/share/omarchy/`, targeted edits in `~/.config/`, interactive `kitty -e` privilege escalation).
  - Hyprland Lua validation protocol (`hyprctl configerrors` and `hyprctl reload`).
  - Single-file modular gotchas protocol and `init-skill.sh` personalization protocol.
  - Step-by-step instructions for creating a new machine profile.
- Implemented user-facing documentation in [`README.md`](file:///home/jmvp/dotfiles/README.md):
  - Highlights Omarchy Quattro native integration, 3-tier architecture, and multi-machine profile model.
  - Quickstart guide and CLI options reference.
  - Hardware profiles catalog (`surface`, `desktop`).
  - New computer profile creation guide and keybinding cheat sheet.

## [2.0.0] - 2026-09-10
### Added
- Restructured `system-personalization` skill for multi-machine Omarchy Quattro support:
  - Created `SKILL.md.template` with customizable variables (`{{HOSTNAME}}`, `{{PRODUCT_NAME}}`, `{{OS}}`, `{{KERNEL}}`, `{{CPU}}`, `{{GPU}}`, `{{PRIMARY_DISPLAY}}`, `{{ACTIVE_PROFILES}}`).
  - Implemented `scripts/init-skill.sh` to automatically probe physical hardware specs, active profiles, and instantiate `SKILL.md`, `references/hardware.md`, and `references/current-state.md`.
  - Implemented modular `references/gotchas/` directory with individual documentation files and `INDEX.md`.
  - Created `templates/gotcha-entry.md` for standardized individual gotcha authoring.
  - Added `scripts/snapshot.sh` for diagnostic status capture.

### Changed
- Converted monolithic `references/gotchas.md` into modular directory structure (`references/gotchas/`).
- Modernized `references/keybindings.md` for Omarchy Quattro on Surface Book 3 (`omarchy`), documenting macOS-style text editing and Surface hardware tablet helpers from `~/.config/hypr/bindings.lua`.
- Updated `references/config-paths.md` to document Omarchy Quattro configuration architecture, rules, and commands.
- Updated `SKILL.md` to version 2.0.0 reflecting live machine specs on Surface Book 3 (`omarchy`).

## [1.16.0] - 2026-08-13
### Added
- Added multi-compositor support for **Niri** in `hyprland-dots` dotfiles repository:
  - Created `niri/.config/niri/cfg/keybinds.kdl` linking **`Alt + Space`** to toggle Noctalia's wallpaper selector (`qs -c noctalia-shell ipc call wallpaper toggle || waypaper`).
  - Added `niri` to `STOW_PKGS` in `scripts/02-stow.sh` for automatic deployment and conflict backups.
- Successfully deployed and validated `hyprland-dots` on remote MacBook Pro running CachyOS Niri (`10.0.0.2`).

## [1.15.0] - 2026-08-10
### Added
- Configured Hyprland `cursor` settings in [`~/.config/hypr/config/inputs.lua`](file:///home/user/.config/hypr/config/inputs.lua):
  - Enabled `inactive_timeout = 3` to automatically hide the mouse cursor after 3 seconds of inactivity (resolving video player cursor visibility issues on websites like Pornhub without breaking games or desktop apps).
  - Enabled `hide_on_key_press = true` to automatically hide the cursor when typing.

## [1.14.0] - 2026-07-30
### Changed
- Replaced `--incognito` flag in [`~/.local/share/applications/Hanime.desktop`](file:///home/user/.local/share/applications/Hanime.desktop) and [`~/.local/share/applications/PH.desktop`](file:///home/user/.local/share/applications/PH.desktop) with `--user-data-dir=/home/user/.config/brave-webapps/containers/diagnostics`.
- Created dedicated diagnostics profile container directory (`~/.config/brave-webapps/containers/diagnostics`) allowing persistent history, cookies, and local session data across launches while remaining completely isolated from the primary user Brave profile.

## [1.13.0] - 2026-07-28
### Added
- Installed **`swayimg`** (`5.4-2.1`) for instant Wayland image and vector previews.
- Created `~/.local/bin/hypr-quicklook` and `~/.local/bin/dolphin-key-helper` scripts to trigger floating Quick Look previews over Dolphin.
- Added KDE Service Menu [`~/.local/share/kio/servicemenus/quicklook.desktop`](file:///home/user/.local/share/kio/servicemenus/quicklook.desktop) for Quick Look context menu action in Dolphin.

### Configured
- Set **Satty** (`satty.desktop`) as the default image viewer across standard MIME types (`image/png`, `image/jpeg`, `image/webp`, `image/gif`, `image/svg+xml`, `image/bmp`) using `xdg-mime default`.
- Configured floating window rules for `swayimg` in [`~/.config/hypr/config/windowrules.lua`](file:///home/user/.config/hypr/config/windowrules.lua#L49).
- Mapped **`ALT` + `Return`** (`Alt+Enter`) in [`~/.config/hypr/config/binds.lua`](file:///home/user/.config/hypr/config/binds.lua#L130) to trigger Quick Look preview overlay ([`~/.local/bin/hypr-quicklook`](file:///home/user/.local/bin/hypr-quicklook)).
- Configured macOS-style **Arrow key navigation** (`Right`/`Down` for next file, `Left`/`Up` for previous file) in [`~/.config/swayimg/config.lua`](file:///home/user/.config/swayimg/config.lua#L6-L10).
- Configured **Kitty** (`kitty.desktop`) as default terminal in [`~/.config/kdeglobals`](file:///home/user/.config/kdeglobals#L4-L5) & [`~/.config/kiorc`](file:///home/user/.config/kiorc#L4-L5), and mapped **`F4`** in Dolphin ([`~/.config/dolphinrc`](file:///home/user/.config/dolphinrc#L15-L17)) to launch Kitty in current folder.
- Preserved Dolphin's native `Space` key behavior for multi-item selection mode.

## [1.12.0] - 2026-07-28
### Added
- Installed **LocalSend** (`cachyos/localsend` v1.17.0-4) via `pacman` for cross-platform local network file sharing.

### Configured
- Configured **UFW Firewall** rules (`53317/tcp` and `53317/udp`) to allow LocalSend discovery broadcast and file receiving across the local network.

## [1.11.0] - 2026-07-26
### Added
- Created desktop launcher `~/.local/share/applications/AniMatrix.desktop` with a custom cyberpunk neon LED matrix app icon in `~/.local/share/applications/icons/AniMatrix.png`.

## [1.2.0] - 2026-07-21
### Added
- Added `SUPER` + `CONTROL` + `I` keybinding to `~/.config/hypr/config/binds.lua` to toggle Noctalia Caffeine (`noctalia msg caffeine-toggle`), preventing automatic screen lock and system sleep during inactivity.

## [1.0.0] - 2026-07-20
### Added
- Initial setup of the `system-personalization` skill under `~/.agents/skills/system-personalization/`.
- Configured local system specs snapshot script (`snapshot.sh`).
- Documented hardware configurations and fractional scaling factors.
- Outlined edit rules for Hyprland Lua configuration modules and Noctalia Wayland Shell TOML settings.
- Documented all active keyboard shortcuts.
- Shallow-cloned the official CachyOS Wiki and Noctalia Docs to `references/` for offline searchability.

### Changed
- Customized touchpad controls in `~/.config/hypr/config/inputs.lua` for macOS-like trackpad behavior:
  - Enabled `natural_scroll`, `tap_to_click`, `clickfinger_behavior`, and `middle_button_emulation`.
  - Switched pointer acceleration profile to `adaptive`.
  - Configured 3-finger horizontal workspace gestures, 3-finger up fullscreen gesture, 3-finger down close gesture, and 4-finger horizontal workspace gesture.
- Documented full Hyprland 0.55+ Lua touchpad option keys, gesture API syntax, and `input.touchpad.tap_to_drag` pitfall in `references/config-paths.md` and `references/gotchas.md`.
- Added Core Rule 7 to `SKILL.md` requiring `hyprctl configerrors` as the first diagnostic step when users report Hyprland system/desktop errors (explaining why `journalctl` does not capture config validation errors).

## [1.1.0] - 2026-07-20
### Added
- Created native Lua `macShortcut` helper function directly in `~/.config/hypr/config/binds.lua` to inspect active window classes (`kitty`, `ghostty`, `alacritty`, etc.) and send context-appropriate key events (`Home`, `End`, `ALT+Left/Right`, `CTRL+Left/Right`, `CTRL+U`, `CTRL+Backspace`) with zero subprocess overhead or modifier bleed.
- Updated `~/.local/bin/hypr-window-pop` toggle logic to use `pinned` and `floating` window state properties directly, fixing toggle-back behavior for `SUPER + O` and `SUPER + SHIFT + O` (PiP mode).
- Added `SHIFT + Print` (Window / Pick screenshot) and `CTRL + Print` (Fullscreen screenshot), perfectly matching `jairo`'s screenshot bindings.
- Created `~/.local/bin/hypr-kbd-brightness` and bound `XF86KbdBrightnessUp` / `XF86KbdBrightnessDown` (`Fn + Up / Down`) to control keyboard backlight brightness (0-3) with custom notifications.
- Added `SHIFT` and `CONTROL` modifiers to screen brightness controls (`XF86MonBrightnessUp / Down`) for fine-tuning (1% steps) and coarse-tuning (10% steps).
- Updated default `kb_options` in `~/.config/hypr/config/inputs.lua` to `""` (Normal PC keyboard layout). Users can manually toggle to Mac layout anytime using `SUPER + ALT + K`.
- Configured `SUPER + K` to open the searchable dynamic keybindings cheat sheet file directly inside a floating, centered terminal.
- Installed Waypaper and bound `ALT + Space` to launch its GUI (with folder/subfolder scanning, random selection, auto-rotate timer, and Noctalia IPC `post_command` integration). Kept `SUPER + SHIFT + W` as the native Noctalia panel.
- Added Core Rule 8 to `SKILL.md` and documented gotcha pattern for launching interactive Kitty terminal windows (`kitty -e bash -c "sudo <command>; ...; read"`) whenever elevated password authentication is required.
- Patched Waypaper's `app.py` with a two-stage progressive rendering engine: Stage 1 renders the first 20 visible wallpapers instantly (< 0.05s) upon launch, while Stage 2 streams the remaining thumbnails asynchronously in the background.



### Changed
- Ported keybindings from `ssh jairo` into `~/.config/hypr/config/binds.lua`:
  - **Convention**: Set `SUPER + <key>` for system operations (Notifications on `SUPER+A`, Session Lock on `SUPER+L`, Float toggle on `SUPER+T`) and `SUPER + SHIFT + <key>` for applications (Zen Browser on `SUPER+SHIFT+B`, LazyGit on `SUPER+SHIFT+A`, LazyDocker on `SUPER+SHIFT+D`, Dolphin on `SUPER+SHIFT+F`, Notes on `SUPER+SHIFT+N`, Yazi on `SUPER+SHIFT+Y`).
- Changed workspace switching in `binds.lua` to match `jairo` layout: `SUPER + 1..9, 0` switches to workspace 1..10, `SUPER + SHIFT + 1..9, 0` moves active window to workspace 1..10, and monitor focus moved to `SUPER + ALT + 1..3`.
  - **Navigation**: Changed focus direction to `CTRL + Arrows`, window position swap to `SUPER + ALT + Arrows`, and workspace cycling to `SUPER + Tab` / `SUPER + SHIFT + Tab`.
  - **macOS Editing**: Enabled `SUPER+Left/Right` (HOME/END), `SUPER+Up/Down` (Doc Top/Bottom), `SUPER+Backspace` (Line backspace), `ALT+Backspace` (Word backspace), `ALT+Left/Right` (Word nav), `ALT+SHIFT+Left/Right` (Word select), `SUPER+C/V/X` (macOS Copy/Paste/Cut).
- Updated `references/keybindings.md` reference sheet with all new mappings.

## [1.2.0] - 2026-07-20
### Added
- Installed **Neovim** (v0.12.4 release) and **LazyGit** (v0.63.1 release) into `~/.local/bin`.
- Cloned and initialized **LazyVim** starter configuration in `~/.config/nvim`.
- Synchronized initial LazyVim plugins and Tree-sitter parsers via headless Neovim execution.

## [1.3.0] - 2026-07-20
### Fixed
- Fixed ZSH character duplication and line corruption (`ccd zigokucdcdd d zzziiggookku`) when SSHing to `jairo`.
- Transferred local `xterm-kitty` terminfo database to `jairo` via `infocmp -a xterm-kitty | ssh jairo "tic -x -"`.
- Added troubleshooting guide for missing terminal terminfo entries over SSH to `references/gotchas.md`.

## [1.4.0] - 2026-07-20
### Added
- Installed `brave-origin-bin` package for native Wayland standalone PWA/Web App support.
- Created Omarchy-compatible CLI scripts `~/.local/bin/cachy-webapp-install` and `cachy-webapp-remove` (with `omarchy-webapp-install` & `omarchy-webapp-remove` symlinks).
- Installed **YouTube** Web App launcher (`~/.local/share/applications/YouTube.desktop`) using Brave Origin engine in Wayland mode.
- Transferred YouTube PNG icon from `jairo` to `~/.local/share/applications/icons/YouTube.png`.
- Bound **YouTube Web App** to `SUPER + SHIFT + Y` in `~/.config/hypr/config/binds.lua` (and moved `yazi` to `SUPER + SHIFT + U`).
- Installed **PH Incognito** Web App launcher (`~/.local/share/applications/PH.desktop`) using Brave Origin engine in Wayland mode (`--incognito`).
- Transferred PH PNG icon from `jairo` to `~/.local/share/applications/icons/Phub.png`.

## [1.5.0] - 2026-07-20
### Added
- Added battery widget to Noctalia top bar in `~/.config/noctalia/config.toml`:
  - Added `"battery"` to `bar.default.end` widgets array.
  - Configured `[widget.battery]` with `display_mode = "graphic"` (animated fill level with percentage overlay).

## [1.6.0] - 2026-07-21
### Added
- Created custom fastfetch layout script `~/.local/bin/fastfetch-custom` featuring a compact layout, 2-column grid for bottom specs, logo padding pushed by 2 spaces for long CPU lines, top vertical separator removed next to logo, full ANSI color palette, bold cyan key styling, and the 16-color palette block line at the bottom.
- Updated `fish_greeting` in `~/.config/fish/config.fish` to launch `fastfetch-custom` on terminal startup, preventing text line-wrapping in split-screen tiled windows while preserving all 21 system specs.

## [1.7.0] - 2026-07-21
### Added
- Created **Hanime** Incognito Web App launcher (`~/.local/share/applications/Hanime.desktop`) using Brave Origin engine in Wayland mode (`--incognito` on `https://hanime.tv/`).
- Created **AllAnime** Web App launcher (`~/.local/share/applications/AllAnime.desktop`) using Brave Origin engine in Wayland mode (updated to `https://allmanga.to/anime`).
- Generated high-resolution custom dark-mode app icons for `Hanime.png` and `AllAnime.png` in `~/.local/share/applications/icons/`.

## [1.10.0] - 2026-07-25
### Changed
- Resolved keybinding conflict between macOS text editing shortcuts and Noctalia system panels in `~/.config/hypr/config/binds.lua`.
- Mapped `SUPER + C` (`CTRL, SHIFT, C`), `SUPER + V` (`CTRL, V`), `SUPER + X` (`CTRL, X`), `SUPER + Z` (`CTRL, Z`), and `SUPER + SHIFT + Z` (`CTRL, SHIFT, Z`) directly in `binds.lua` using native `hl.dsp.send_shortcut`. This eliminates external shell invocation latency and avoids modifier key collisions.
- Remapped Noctalia Control Center toggle to `SUPER + E` (`noctalia msg panel-toggle control-center`).
- Remapped Noctalia Settings toggle to `SUPER + ,` (`noctalia msg settings-toggle`).
- Updated keybindings reference sheet in `references/keybindings.md`.

---

## 2026-08-10 — Automated Dotfiles Repository & GNU Stow Setup

### Changes
- Installed `stow` and created the `~/dotfiles` Git repository for automated machine provisioning.
- Modularized configurations into Stow package groups:
  - `hypr`: `~/.config/hypr/` (modular Lua configs + portable monitor fallback)
  - `noctalia`: `~/.config/noctalia/` (shell panels & widgets)
  - `kitty`: `~/.config/kitty/`
  - `alacritty`: `~/.config/alacritty/`
  - `fish`: `~/.config/fish/config.fish`
  - `btop`: `~/.config/btop/`
  - `waypaper`: `~/.config/waypaper/`
  - `gtk`: `~/.config/gtk-3.0/`, `~/.config/gtk-4.0/`, `~/.config/nwg-look/`
  - `swayimg`: `~/.config/swayimg/`
  - `bin`: `~/.local/bin/` (`mac-key-helper`, `hypr-window-pop`, `hypr-toggle-altwin`, `fastfetch-custom`, etc.)
  - `agents`: `~/.agents/` (system personalization intelligence and documentation)
  - `webapps`: `~/.local/share/applications/` (custom .desktop launchers and high-res icons)
  - `zigoku`: `~/.config/zigoku/` (anime client configuration)
- Built automated 1-command installer `install.sh` and modular provisioning scripts (`scripts/01-packages.sh`, `scripts/02-stow.sh`, `scripts/03-services.sh`, `scripts/04-shell.sh`).
- Created safe backup system in `02-stow.sh` to prevent conflict errors when stowing on existing configurations.
- Exported explicit official/CachyOS package snapshot to `packages/pacman-packages.txt`.
- Published repository to GitHub as [`JValdivia23/hyprland-dots`](https://github.com/JValdivia23/hyprland-dots).
