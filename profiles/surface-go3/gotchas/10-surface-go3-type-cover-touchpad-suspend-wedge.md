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

The failure is a `hid-multitouch` / `usbhid` control-transfer timeout, not a missing USB reset-resume quirk:

1. On suspend, `hid_suspend()` (non-autosuspend branch) calls `hid_driver_suspend()` first. `mt_suspend()` calls `mt_set_modes(HID_LATENCY_HIGH, ...)`, which queues `SET_REPORT` feature transfers (Latency Mode `0x07`; Surface/Button Switch `0x10`) through usbhid's control queue.
2. The Type Cover does not complete that control transfer in the cover-closed/lid-close suspend path. `usbhid_wait_io()` then waits the full `10*HZ` (`usbhid_wait_io()` timeout) and returns `-EIO`, which becomes the `usbhid 1-7:1.3: suspend error -5` line and aborts the `s2idle` transition.
3. The `usb_submit_urb(ctrl) failed: -1` (`-EPERM`) line is a **secondary artifact** of cleanup, not the original failure. After the 10 s timeout, `hid_cease_io()` calls `usb_kill_urb(usbhid->urbctrl)`. `usb_kill_urb()` raises `urb->reject` and waits for the URB's completion to finish. The killed URB's `hid_ctrl()` completion handler advances the queue and calls `hid_submit_ctrl()` for the next queued report while `reject` is still set, so `usb_submit_urb()` returns `-EPERM` and logs `failed: -1`.
4. `mt_resume()` also calls `mt_set_modes(HID_LATENCY_NORMAL, TOUCHPAD_REPORT_ALL)`. If those `SET_REPORT`s stay pending after wake, the **next** suspend's `usbhid_wait_io()` waits on them and fails the same way. This is why a suspend-only quirk still produced intermittent `suspend error -5` on back-to-back cycles even though the touchpad itself kept working.
5. Because the suspend callback returns `-EIO`, the interface is left half-suspended and the touchpad can stop delivering events after the aborted/resumed cycle. The keyboard interfaces on `1-7:1.0`/`1-7:1.1` are unaffected.

`intel-hid INT33D5:00: unknown event 0xcb` is emitted by the EC (`_QD7`/`_QD8`/`_Q18` in the DSDT) when the Type Cover enters the closed/folded state. It is a reliable timing marker for the same lid-close event, but it is not the cause of the USB failure.

`/sys/bus/usb/devices/1-7/quirks` is `0x0` and `power/control` is `on` (runtime autosuspend is not the trigger). The linux-surface `USB_QUIRK_DELAY_INIT` for `045e:09b5` only addresses touchpad pointer-mode initialization; it does not fix this suspend path. Upstream linux-surface issue [#1223](https://github.com/linux-surface/linux-surface/issues/1223) reports the same 10 s abort on the same `045e:09b5` / `1-7:1.3` combination.

## Solution & Fix

### 1. Permanent DKMS Quirk (Active)

Implemented a targeted `hid-multitouch` quirk for `045e:09b5` in the repo-local driver source at `devices/surface-go-3/hid-multitouch/src/hid-multitouch.c`:

- Added `MT_QUIRK_NO_SUSPEND_MODES` (`BIT(27)`) and `MT_CLS_WIN_8_NO_SUSPEND_MODES` (`0x001a`), using the same base quirks as `MT_CLS_WIN_8`.
- Added a specific `HID_DEVICE(BUS_USB, HID_GROUP_MULTITOUCH_WIN_8, USB_VENDOR_ID_MICROSOFT, 0x09b5)` entry ahead of the generic Win 8 entry, so only this Type Cover gets the quirk.
- `mt_suspend()` returns immediately when the quirk is set, leaving the latency/report modes unchanged across sleep.
- `mt_resume()` also returns immediately. Skipping only `mt_suspend()` was not sufficient: the resume path queued three `SET_REPORT`s that could stay pending and make the *next* suspend wait 10 s.

Packaged as DKMS `surface-go3-hid-multitouch/0.1.0` (`devices/surface-go-3/hid-multitouch/dkms.conf`) and installed to `/lib/modules/7.2.15-1-omarchy/updates/dkms/hid-multitouch.ko.zst` (the stock module is archived by DKMS). The installed module reports `srcversion 2519D6F64F70642A0DC752F`.

**Boot image inclusion:** DKMS archived the stock `hid-multitouch`, so mkinitcpio's `keyboard` hook (which scans only the stock `kernel/drivers/hid` tree) omitted the module from the first rebuilt UKI. Added `/etc/mkinitcpio.conf.d/zz-surface-go3-hid-multitouch.conf` with `MODULES+=(hid_multitouch)` (repo copy at `devices/surface-go-3/hid-multitouch/mkinitcpio.conf.d/zz-surface-go3-hid-multitouch.conf`) and rebuilt the boot UKI with `pkexec limine-mkinitcpio`. The `zz-` prefix is required: `99-` sorts before `surface_device_modules.conf`, whose `MODULES=(...)` assignment resets the array and discards the append. After a kernel update, verify DKMS rebuilt the module and that the new UKI still embeds `updates/dkms/hid-multitouch.ko.zst`; if the DKMS build fails, the stock module is used and the suspend quirk is absent.

Test results:

- Suspend-only variant: the touchpad woke every time, but 3 of 4 cycles still logged `usbhid 1-7:1.3: suspend error -5` because of pending resume transfers.
- Suspend+resume-skip variant: function-graph tracing showed `mt_suspend` at ~1.8–2.2 µs, `usbhid_wait_io` under 1 µs per call, and `mt_resume` at ~3.4–3.8 µs with no `mt_set_modes()` or `hid_hw_idle()` calls. Three recorded back-to-back lid-close `s2idle` cycles completed cleanly, with zero `suspend error -5` or `usb_submit_urb(ctrl) failed` since the final reload.
- Boot image: `/boot/EFI/Linux/omarchy_linux-omarchy.efi` now embeds `usr/lib/modules/7.2.15-1-omarchy/updates/dkms/hid-multitouch.ko.zst` (sha256 `f9cc4e4f059d26fef81f37087646cc4e72601fb8db4027f4af4af0c0508dd8dd`, matching the installed DKMS module) and no stock `kernel/drivers/hid/hid-multitouch.ko.zst`; the Limine entry's BLAKE2b-512 hash (`e7c51fbd…`) matches `b2sum` of the new image.
- **Reboot verification pending.** The temporary recovery unit is intentionally neutralized by a no-op drop-in until the first post-reboot suspend test passes.

### 2. Alternative / Complementary Fixes (not installed)

1. **usbhid hardening:** skip `hid_submit_ctrl()` from `hid_ctrl()` when `urb->reject` is set, which suppresses the `-EPERM` cleanup race. This alone does **not** fix the 10 s suspend abort because the original transfer still never completes.
2. Keep the temporary unbind/rebind recovery unit available until the DKMS quirk has survived a reboot and a post-reboot lid-close test.

### 3. Temporary Automatic Wake Recovery (Fallback, currently neutralized)

Installed a local systemd resume unit ([surface-go3-touchpad-resume.service](file:///etc/systemd/system/surface-go3-touchpad-resume.service)) and helper script ([surface-go3-touchpad-recover](file:///usr/local/bin/surface-go3-touchpad-recover)) outside `~/dotfiles` (since it is temporary):

- **Trigger**: `WantedBy` / `After` `suspend.target`, `hibernate.target`, `hybrid-sleep.target`, and `suspend-then-hibernate.target`.
- **Action**:
  1. Dynamically locates USB devices matching `045e:09b5` and `bInterfaceNumber == 03` (e.g. `1-7:1.3`).
  2. Stops `edgepad.service` for any active user sessions running it so `/dev/input/event*` is cleanly released.
  3. Unbinds and rebinds that interface on `/sys/bus/usb/drivers/usbhid` (with a `0.5s` delay) and runs `udevadm settle --timeout=5`.
  4. Restarts `edgepad.service` for those user sessions.

**Test neutralization:** While validating the DKMS quirk, a temporary drop-in `/etc/systemd/system/surface-go3-touchpad-resume.service.d/90-test-noop.conf` overrides `ExecStart` with `/bin/true`, so the recovery unit cannot mask a failed suspend. Remove it after the post-reboot test:

```bash
sudo rm -f /etc/systemd/system/surface-go3-touchpad-resume.service.d/90-test-noop.conf
sudo systemctl daemon-reload
```

**Removal after post-reboot verification:**

```bash
sudo rm -f /etc/systemd/system/surface-go3-touchpad-resume.service.d/90-test-noop.conf
sudo systemctl disable --now surface-go3-touchpad-resume.service
sudo rm -f /etc/systemd/system/surface-go3-touchpad-resume.service /usr/local/bin/surface-go3-touchpad-recover
sudo systemctl daemon-reload
```

### 4. Manual Live Recovery

Stop `edgepad.service` so `/dev/input/event7` is released, unbind and rebind USB HID interface `1-7:1.3` via `usbhid`, wait for udev (`70-edgepad.rules` `uaccess` ACLs), and restart `edgepad.service`:

```bash
sudo /usr/local/bin/surface-go3-touchpad-recover
# or manually:
systemctl --user stop edgepad.service && \
pkexec bash -c 'echo -n "1-7:1.3" > /sys/bus/usb/drivers/usbhid/unbind && sleep 0.5 && echo -n "1-7:1.3" > /sys/bus/usb/drivers/usbhid/bind && udevadm settle --timeout=5' && \
systemctl --user start edgepad.service
```

## Verification

1. Confirm the DKMS quirk is the loaded driver and that the device matched the specific entry:
   ```bash
   dkms status | grep surface-go3-hid-multitouch
   modinfo -F filename hid_multitouch
   journalctl -k -b | grep 'skipping mode changes during system suspend'
   ```
   Expected: module path under `/lib/modules/7.2.15-1-omarchy/updates/dkms/`, and the quirk message for `0003:045E:09B5.*`.
2. Confirm the boot UKI embeds the DKMS module and not the stock copy:
   ```bash
   lsinitcpio -l /boot/EFI/Linux/omarchy_linux-omarchy.efi | grep -E 'updates/dkms/hid-multitouch|kernel/drivers/hid/hid-multitouch'
   ```
   Expected: only `usr/lib/modules/7.2.15-1-omarchy/updates/dkms/hid-multitouch.ko.zst`.
3. After a lid-close/open cycle, confirm the suspend did not time out:
   ```bash
   journalctl -k -b -o short-monotonic | grep -E 'PM: suspend entry|PM: suspend exit|suspend error'
   ```
   Expected: no `usbhid 1-7:1.3: suspend error -5` and no 10 s gap between entry and exit.
4. Confirm `hid-multitouch` and `edgepad` re-attached cleanly:
   ```bash
   journalctl -k -n 10 --no-pager
   edgepad doctor
   ```
   Expected: kernel logs `Microsoft Surface Keyboard Touchpad` and `edgepad virtual touchpad` re-probing, and `edgepad doctor` reports `ok=15 warn=0 fail=0` (`result: ready`).
5. Confirm Hyprland lists both `microsoft-surface-keyboard-touchpad` and `edgepad-virtual-touchpad` under `hyprctl devices`, and moving a finger on the trackpad moves the cursor.

## Related References
- [`references/config-paths.md`](../config-paths.md)
- [`06-edgepad-uaccess-uinput.md`](06-edgepad-uaccess-uinput.md)
- [`03-surface-go3-scaling-and-touch.md`](03-surface-go3-scaling-and-touch.md)
