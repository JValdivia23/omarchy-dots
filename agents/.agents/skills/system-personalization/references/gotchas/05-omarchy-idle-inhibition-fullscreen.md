# Fullscreen Media Playback Idle Sleep & Screensaver Interruptions

- **ID**: `05-omarchy-idle-inhibition-fullscreen`
- **Category**: `Wayland | Hyprland | Power | System`
- **Hardware / Target**: `Universal (Omarchy)`
- **Severity**: `Warning`

---

## Symptom
While watching YouTube, streaming video, or playing media in fullscreen, the system goes to sleep as idle after the standard inactivity timeout (Omarchy screensaver launches after 150 seconds, screen locks and display turns off via DPMS after 300 seconds).

## Root Cause
This issue is caused by two overlapping factors in Omarchy:
1. **Broken XDG Desktop Portal Inhibit Backend:** Web browsers (Brave, Chromium, Firefox) attempt to inhibit idle during video playback via the XDG Desktop Portal (`org.freedesktop.portal.Inhibit`). In Omarchy, `hyprland-portals.conf` delegates to `xdg-desktop-portal-gtk`, which looks for GNOME's `org.freedesktop.ScreenSaver` or `org.gnome.SessionManager` on D-Bus. Neither service exists in Omarchy, causing the portal inhibit call to fail silently:
   ```text
   xdg-desktop-portal-gtk: Backend call failed: Cannot invoke method; proxy is for the well-known name org.freedesktop.ScreenSaver without an owner
   ```
2. **Missing Window Rule for Browsers / Fullscreen Windows:** Omarchy ships default window rules for games (`Steam`, `Moonlight`, `RetroArch`, `GeForceNOW`) with `idle_inhibit = "fullscreen"`, but omits browsers and generic fullscreen windows. Therefore, Hyprland does not automatically tell Quickshell's `IdleMonitor` (`ext-idle-notify-v1`) to pause when a browser video goes fullscreen.

## Solution & Fix
Add a universal window rule in `core/.config/hypr/hyprland.lua`:

```lua
-- Inhibit idle (screensaver & sleep) when any window is fullscreen (e.g. YouTube, Netflix, media players, games)
o.window(".*", { idle_inhibit = "fullscreen" })
```

Then reload Hyprland:
```bash
hyprctl reload
hyprctl configerrors
```

When any window enters fullscreen, Hyprland sets `idleinhibit fullscreen`, keeping the display awake and suppressing the screensaver. Once the window leaves fullscreen, normal idle behavior immediately resumes.

## Verification
1. Open a video in fullscreen.
2. Verify with `hyprctl clients -j | jq '.[] | {class, fullscreen, inhibitingIdle}'` that `fullscreen` is active and `inhibitingIdle` is `true`.
3. Check `omarchy-shell idle status` to ensure `idle` remains `false` past the 150-second screensaver deadline.

## Related References
- [`references/config-paths.md`](../config-paths.md)
