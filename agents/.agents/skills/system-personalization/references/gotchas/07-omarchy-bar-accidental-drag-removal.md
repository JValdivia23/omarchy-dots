# Omarchy Status Bar Widget Drag & Accidental Removal ("Poof")

- **ID**: `07-omarchy-bar-accidental-drag-removal`
- **Category**: `Wayland / Input`
- **Hardware / Target**: `Universal (especially Laptops with Touchpads)`
- **Severity**: `Warning`

---

## Symptom

Status bar icons/widgets suddenly disappear from the Omarchy status bar during normal trackpad or mouse navigation, clicking, or dragging. Users report losing widgets (such as CPU monitors, media controls, or system update icons) without intentionally deleting them.

## Root Cause

Omarchy shell's upstream bar implementation (`/usr/share/omarchy/shell/plugins/bar/Bar.qml`) allows widget reordering via bare left-click dragging.
1. The drag threshold is only ~16px (`Style.space(4)`).
2. If a widget is dragged 48px off the bar (`barDragRemoveDistance`), removal is armed (`barDragRemoveArmed`).
3. Releasing the mouse button triggers a macOS-style "poof" animation and calls `removeBarDrag()`, which permanently deletes the widget entry from `shell.json` without confirmation.
4. On laptops with sensitive trackpads, small finger movements or taps can easily surpass these low distance thresholds and discard widgets unintentionally. Upstream Omarchy does not provide a native `bar.locked` toggle.

## Solution & Fix

Clone the built-in bar plugin into user space via Omarchy's official plugin system and guard dragging and removal behind a lock setting and modifier requirement:

1. **Clone the bar plugin:**
   ```bash
   omarchy plugin clone omarchy.bar
   ```
   This creates `~/.config/omarchy/plugins/<user>.bar/` (version-controlled in `~/dotfiles/core/.config/omarchy/plugins/<user>.bar/`) and switches `shell.json` to use it.

2. **Add lock check and require Super for removal:**
   In `Bar.qml`:
   - Define `readonly property bool barLocked: !(root.barConfig && root.barConfig.locked === false)`
   - In `onPositionChanged`, block dragging when locked unless `hasSuper`:
     ```qml
     var hasSuper = (mouse.modifiers & Qt.MetaModifier) !== 0
     if (!canReorder || !(mouse.buttons & Qt.LeftButton) || (barLocked && !hasSuper)) return
     ```
   - Only arm removal when `hasSuper`:
     ```qml
     root.setBarDragRemoveArmed(!drop && hasSuper && root.moduleRemoveDistance(screenPoint) >= root.barDragRemoveDistance)
     ```
   - In `onReleased`, only remove when `hasSuper`:
     ```qml
     var hasSuper = (mouse.modifiers & Qt.MetaModifier) !== 0
     if (root.barDragSource === slot && root.barDragRemoveArmed && hasSuper) root.removeBarDrag(slot)
     else if (root.barDragSource === slot) root.settleBarDrag(slot)
     ```

3. **Set `"locked": true` in `shell.json`:**
   Add `"locked": true` under `"bar"` in `~/.config/omarchy/shell.json`.

## Verification

1. Left-click, hold, and attempt to drag an icon on the status bar without holding Super: the icon stays firmly locked in place and does not drag.
2. Hold `Super` + left-click and drag: the widget lifts and can be reordered on the bar.
3. Hold `Super` + drag off the bar: the ghost dims and releasing removes the widget.
4. Dragging off the bar without Super snaps the widget safely back to its position without deletion.

## Related References
- [`references/config-paths.md`](../config-paths.md)
- [`core/.config/omarchy/shell.json`](../../../../core/.config/omarchy/shell.json)
