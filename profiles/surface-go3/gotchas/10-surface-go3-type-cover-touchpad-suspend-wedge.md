# Surface Go 3 Type Cover Touchpad Wedged After Suspend/Resume

- **ID**: `10-surface-go3-type-cover-touchpad-suspend-wedge`
- **Category**: `Hardware / Input / Power`
- **Hardware / Target**: `Microsoft Surface Go 3 (Type Cover 045e:09b5)`
- **Severity**: `Warning`

---

## Symptom

After waking the Surface Go 3 from `s2idle` suspend, the Type Cover touchpad stops moving the pointer or generating input events while the Type Cover keyboard continues typing normally.

Because Hyprland also hides the mouse cursor on keyboard input (`cursor:hide_on_key_press = true`), touchscreen input (`cursor:hide_on_touch = true`), and inactivity (`cursor:inactive_timeout = 3`), the pointer disappears and moving fingers across the trackpad neither moves nor unhides the cursor. Touchscreen input (`ELAN9038:00 04F3:2A1C`) continues working.

Diagnostics while wedged:
- `edgepad.service` remains `active (running)` with `/dev/input/event7` open, and `edgepad doctor` still passes (`ok=15 warn=0 fail=0`), but `/proc/<edgepad-pid>/io` read/write counters stay completely static even when touching the trackpad.
- `journalctl -k -b` shows a `usbhid` / `hid-multitouch` error on the Type Cover touchpad USB interface (`1-7:1.3`) during the suspend/resume transition:

```text
hid-multitouch 0003:045E:09B5.0004: usb_submit_urb(ctrl) failed: -1
usbhid 1-7:1.3: suspend error -5
```

## Root Cause

The Microsoft Surface Type Cover (`045e:09b5`) exposes separate USB HID interfaces under the same device (`1-7`):
- `1-7:1.0` / `1-7:1.1`: Keyboard and consumer/system control (`hid-generic`) — recover normally after wake.
- `1-7:1.3`: Precision Touchpad (`hid-multitouch`, `/dev/input/event7`) — fails its control URB during `s2idle` suspend/resume (`suspend error -5` / `-EIO`), leaving the touchpad interface unresponsive after resume.

`/sys/bus/usb/devices/1-7/quirks` is `0x0` (no USB reset-resume quirk configured), and no `systemd-sleep` post-resume rebind hook is currently installed.

*(Note: This is a **temporary** workaround until the underlying kernel/driver suspend-resume issue is fixed.)*

## Solution & Fix

### 1. Temporary Automatic Wake Recovery (Active)

Installed a local systemd resume unit ([surface-go3-touchpad-resume.service](file:///etc/systemd/system/surface-go3-touchpad-resume.service)) and helper script ([surface-go3-touchpad-recover](file:///usr/local/bin/surface-go3-touchpad-recover)) outside `~/dotfiles` (since it is temporary):

- **Trigger**: `WantedBy` / `After` `suspend.target`, `hibernate.target`, `hybrid-sleep.target`, and `suspend-then-hibernate.target`.
- **Action**:
  1. Dynamically locates USB devices matching `045e:09b5` and `bInterfaceNumber == 03` (e.g. `1-7:1.3`).
  2. Stops `edgepad.service` for any active user sessions running it so `/dev/input/event*` is cleanly released.
  3. Unbinds and rebinds that interface on `/sys/bus/usb/drivers/usbhid` (with a `0.5s` delay) and runs `udevadm settle --timeout=5`.
  4. Restarts `edgepad.service` for those user sessions.

**Removal once kernel/driver is fixed:**

```bash
sudo systemctl disable --now surface-go3-touchpad-resume.service
sudo rm -f /etc/systemd/system/surface-go3-touchpad-resume.service /usr/local/bin/surface-go3-touchpad-recover
sudo systemctl daemon-reload
```

### 2. Manual Live Recovery

Stop `edgepad.service` so `/dev/input/event7` is released, unbind and rebind USB HID interface `1-7:1.3` via `usbhid`, wait for udev (`70-edgepad.rules` `uaccess` ACLs), and restart `edgepad.service`:

```bash
sudo /usr/local/bin/surface-go3-touchpad-recover
# or manually:
systemctl --user stop edgepad.service && \
pkexec bash -c 'echo -n "1-7:1.3" > /sys/bus/usb/drivers/usbhid/unbind && sleep 0.5 && echo -n "1-7:1.3" > /sys/bus/usb/drivers/usbhid/bind && udevadm settle --timeout=5' && \
systemctl --user start edgepad.service
```

## Verification

1. Confirm `hid-multitouch` and `edgepad` re-attached cleanly:
   ```bash
   journalctl -k -n 10 --no-pager
   edgepad doctor
   ```
   Expected: kernel logs `Microsoft Surface Keyboard Touchpad` and `edgepad virtual touchpad` re-probing, and `edgepad doctor` reports `ok=15 warn=0 fail=0` (`result: ready`).
2. Confirm Hyprland lists both `microsoft-surface-keyboard-touchpad` and `edgepad-virtual-touchpad` under `hyprctl devices`, and moving a finger on the trackpad moves the cursor.

## Related References
- [`references/config-paths.md`](../config-paths.md)
- [`06-edgepad-uaccess-uinput.md`](06-edgepad-uaccess-uinput.md)
- [`03-surface-go3-scaling-and-touch.md`](03-surface-go3-scaling-and-touch.md)
