# Microsoft Surface Book Tablet Detachment (`surface-dtx`)

- **ID**: `04-surface-dtx-tablet-detach`
- **Category**: `Hardware / System`
- **Hardware / Target**: `Microsoft Surface Book (1, 2, and 3)`
- **Severity**: `Warning`

---

## Symptom
1. Pressing the physical hardware detach key on the Surface Book keyboard does not release the screen latch, or produces no feedback.
2. In tablet mode or when using external keyboards, the user has no physical button to release the keyboard base.
3. Attempting to detach while running discrete GPU applications results in software detachment lockouts.

## Root Cause
The Surface Book clipboard (screen/tablet portion) connects to the keyboard base via a muscle-wire (Shape Memory Alloy) mechanical latch. The detachment mechanism is orchestrated by the Surface Detachment System (DTX) hardware controller.

On Linux, the `surface-dtx-daemon` user-space service communicates with the DTX kernel driver to monitor latch state, validate detachment conditions (e.g. tablet battery level > 10%, dGPU unmounted), and actuate the latch coils. If software detach requests are not sent through the DTX subsystem, the latch remains physically locked.

## Solution & Fix

### 1. Software Detach Command
Request latch release from terminal or script using the `surface` CLI:
```bash
surface dtx request
```
If the command succeeds, an audible mechanical click will sound, the keyboard latch LED flashes green, and the tablet can be lifted off the base.

### 2. Hyprland Keybinding (`~/.config/hypr/bindings.lua`)
Bind `SUPER + D` to request detachment and dispatch an Omarchy notification:
```lua
-- Surface Book tablet helpers
-- Hardware detach button works; SUPER+D requests latch-open via surface-dtx-daemon.
o.bind("SUPER + D", "Detach Surface base", "sh -c 'surface dtx request 2>/dev/null && omarchy notification send \"Surface detach\" \"Latch opening - pull the tablet.\" || omarchy notification send \"Surface detach\" \"Hold the hardware detach key.\"'")
```

### 3. Detachment Diagnostics & Troubleshooting
If the latch refuses to release:
- **Check Latch & Device Mode Status**:
  ```bash
  surface dtx get-latchstatus
  surface dtx get-devicemode
  ```
- **Check Service State**:
  Ensure the daemon is active:
  ```bash
  systemctl status surface-dtx-daemon.service
  ```
- **Cancel Hung Detachment**:
  If a detachment was triggered but the tablet was not separated:
  ```bash
  surface dtx cancel
  ```
- **Battery Safety Lock**: If tablet battery (`BAT1` or `BAT2`) is below 10%, Surface firmware locks the latch to prevent sudden power loss. Connect the charger before detaching.
- **dGPU Lockout**: If discrete GPU processes are active in the base, close the application or run `surface dgpu power-off` if safe.

## Verification
Run:
```bash
surface dtx get-latchstatus
```
Confirm status reports `Closed` when attached, and transitions to `Open` when `surface dtx request` is invoked.

## Related References
- [`~/.config/hypr/bindings.lua`](file:///home/jmvp/.config/hypr/bindings.lua)
- Linux Surface DTX Subsystem: `https://github.com/linux-surface/surface-dtx-daemon`
