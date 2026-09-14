# Known Gotchas & Troubleshooting Index

A modular directory of universal pitfalls, guardrails, and troubleshooting procedures for Omarchy Quattro. Each gotcha is stored in an individual file so agents and developers can consult only what is relevant to their current task without reading unnecessary context.

---

## Universal Guardrails (All Machines)

These gotchas represent core operating guardrails across all installations running Omarchy Quattro:

| ID / File | Title | Category | Target Hardware | Severity |
|-----------|-------|----------|-----------------|----------|
| [`01-hyprland-lua-validation.md`](01-hyprland-lua-validation.md) | Hyprland Lua Configuration Error Diagnostics | Hyprland | Universal | Critical |
| [`02-omarchy-read-only-safety.md`](02-omarchy-read-only-safety.md) | Omarchy Package Space Read-Only Safety (`/usr/share/omarchy/`) | System | Universal (Omarchy) | Critical |
| [`03-elevated-password-prompts.md`](03-elevated-password-prompts.md) | Interactive Password Authentication for Sudo Operations (`kitty -e`) | System / Security | Universal | Critical |
| [`04-omarchy-fish-quattro-integration.md`](04-omarchy-fish-quattro-integration.md) | Omarchy Quattro Fish Shell Integration & Autosuggestions | System | Universal (Omarchy) | Warning |

---

## Hardware-Specific Profile Gotchas

Hardware-specific workarounds live inside each profile directory under `profiles/<profile>/gotchas/` (e.g. `profiles/surface/gotchas/`). During installation (`./install.sh`), they are automatically symlinked into `~/.agents/skills/system-personalization/references/gotchas/` on machines matching that profile.

| ID / File | Title | Category | Target Hardware | Severity |
|-----------|-------|----------|-----------------|----------|
| [`03-surface-scaling-and-touch.md`](03-surface-scaling-and-touch.md) | Surface Book Display Scaling & Touchscreen Alignment | Display / Input | Microsoft Surface | Warning |
| [`04-surface-dtx-tablet-detach.md`](04-surface-dtx-tablet-detach.md) | Surface Book Tablet Detachment (`surface-dtx`) | Hardware / System | Microsoft Surface Book | Warning |
| [`07-fcitx5-wayland-virtual-keyboard.md`](07-fcitx5-wayland-virtual-keyboard.md) | Fcitx5 Wayland Virtual Keyboard Compatibility | Input / Wayland | Microsoft Surface | Info |
| [`08-surface-book-usb-c-charging-quirks.md`](08-surface-book-usb-c-charging-quirks.md) | Surface Book USB-C Charging Deadlocks & Power Delivery Flapping | Hardware / Power | Microsoft Surface Book | Warning |
| [`09-surface-kernel-limine-boot-default.md`](09-surface-kernel-limine-boot-default.md) | Surface Kernel Default Boot Order in Limine Bootloader | Hardware / System | Microsoft Surface | Warning |

On fresh or standard desktop systems without a specialized profile, this directory remains clean with only the universal guardrails above.

---

## Authoring New Gotchas

When discovering a new system quirk, API change, or hardware workaround:
1. Read the comprehensive authoring guide: [`HOW_TO_WRITE_A_GOTCHA.md`](HOW_TO_WRITE_A_GOTCHA.md).
2. Copy the standardized template from [`../../templates/gotcha-entry.md`](../../templates/gotcha-entry.md).
3. Place universal gotchas here or profile-specific gotchas in `profiles/<profile>/gotchas/`.
4. Update [`../changelog.md`](../changelog.md) recording the discovery and resolution.
