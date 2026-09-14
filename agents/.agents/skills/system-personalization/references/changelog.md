# System Personalization Changelog

A dated log of all package changes, configurations, script modifications, and hardware upgrades.

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



