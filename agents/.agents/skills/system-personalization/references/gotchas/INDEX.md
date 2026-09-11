# Known Gotchas & Troubleshooting Index

A modular directory of pitfalls, hardware quirks, and troubleshooting procedures. Each gotcha is stored in an individual file so agents and developers can consult only what is relevant to their current task without reading unnecessary context.

---

## Gotchas Directory

| ID / File | Title | Category | Target Hardware | Severity |
|-----------|-------|----------|-----------------|----------|
| [`01-hyprland-lua-validation.md`](01-hyprland-lua-validation.md) | Hyprland Lua Configuration Error Diagnostics | Hyprland | Universal | Critical |
| [`02-omarchy-read-only-safety.md`](02-omarchy-read-only-safety.md) | Omarchy Package Space Read-Only Safety (`/usr/share/omarchy/`) | System | Universal (Omarchy) | Critical |
| [`03-surface-scaling-and-touch.md`](03-surface-scaling-and-touch.md) | Microsoft Surface Display Scaling & Touchscreen Configuration | Display / Input | Microsoft Surface | Warning |
| [`04-surface-dtx-tablet-detach.md`](04-surface-dtx-tablet-detach.md) | Microsoft Surface Book Tablet Detachment (`surface-dtx`) | Hardware | Microsoft Surface Book | Warning |
| [`05-asus-supergfxctl-hybrid.md`](05-asus-supergfxctl-hybrid.md) | ASUS ROG Dual GPU Switching (`supergfxctl`) & Power Management | Hardware / Graphics | ASUS ROG Laptops | Warning |
| [`06-elevated-password-prompts.md`](06-elevated-password-prompts.md) | Interactive Password Authentication for Sudo Operations (`kitty -e`) | System / Security | Universal | Critical |
| [`07-fcitx5-wayland-virtual-keyboard.md`](07-fcitx5-wayland-virtual-keyboard.md) | Wayland On-Screen Virtual Keyboard with Fcitx5 | Input / Wayland | Touchscreen / Tablets | Warning |
| [`08-localsend-ufw-firewall.md`](08-localsend-ufw-firewall.md) | LocalSend LAN Discovery & Transfer Blocked by UFW Firewall | Networking / Firewall | Universal | Warning |
| [`09-kitty-ssh-terminfo.md`](09-kitty-ssh-terminfo.md) | Remote SSH Hosts Lack `xterm-kitty` Terminfo (Character Duplication) | Terminal / SSH | Universal | Warning |

---

## Adding New Gotchas

When discovering a new system quirk, API change, or workaround:
1. Copy the template from [`../../templates/gotcha-entry.md`](../../templates/gotcha-entry.md).
2. Create a new markdown file named `references/gotchas/<next-number>-<short-slug>.md`.
3. Fill out the **Symptom**, **Root Cause**, **Solution & Fix**, and **Verification** sections.
4. Add a new row to the index table above.
5. Update [`../changelog.md`](../changelog.md) recording the addition.
