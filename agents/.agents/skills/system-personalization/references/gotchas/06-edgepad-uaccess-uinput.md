# EdgePad Udev Uaccess & Uinput Permissions

- **ID**: `06-edgepad-uaccess-uinput`
- **Category**: `Input / System`
- **Hardware / Target**: `Universal (Laptops with Touchpad)`
- **Severity**: `Warning`

---

## Symptom

When running `edgepad doctor` or starting `edgepad.service`, EdgePad fails to discover the touchpad or fails to initialize the virtual proxy device with errors such as:

```text
Config
  fail  device     no touchpad candidates found under /dev/input
Device
  fail  uinput     failed to open /dev/uinput read/write: Permission denied (os error 13)
Access
  fail  acl        missing rw ACL for user; touchpad_acl=false uinput_acl=false
```

## Root Cause

1. **Touchpad evdev permissions**: By default on Arch / Omarchy Linux, raw input event nodes under `/dev/input/event*` are owned by `root:input` (`0660`). Active local login users on `seat0` do not have read/grab access without an explicit `uaccess` tag assigned by `systemd-logind`.
2. **Virtual input permissions & module loading**: `/dev/uinput` defaults to `root:root` (`0600`). Additionally, the `uinput` kernel module is built as a loadable module on Arch/Omarchy (`uinput.ko.zst`) and is not automatically inserted into the kernel until explicitly loaded or configured in `/etc/modules-load.d/`.
3. **EdgePad architecture**: Because EdgePad grabs the physical touchpad, claims touches along configured edges (e.g. volume on right edge, brightness on left edge), and passes normal center pointer events through a virtual `/dev/uinput` touchpad to Hyprland, it requires read/grab permissions on the physical touchpad node and read/write permissions on `/dev/uinput`.

## Solution & Fix

1. **Deploy the EdgePad uaccess udev rule**:
   Create `/etc/udev/rules.d/70-edgepad.rules`:
   ```udev
   # Grant the active local seat user access through systemd-logind uaccess ACLs.
   SUBSYSTEM=="input", KERNEL=="event*", ENV{ID_INPUT_TOUCHPAD}=="1", TAG+="uaccess"
   SUBSYSTEM=="misc", KERNEL=="uinput", TAG+="uaccess", OPTIONS+="static_node=uinput"
   ```

2. **Ensure automatic kernel module loading on boot**:
   Create `/etc/modules-load.d/uinput.conf`:
   ```text
   uinput
   ```

3. **Reload kernel modules and udev triggers**:
   ```bash
   sudo modprobe uinput
   sudo udevadm control --reload
   sudo udevadm trigger --subsystem-match=input --action=change
   sudo udevadm trigger --subsystem-match=misc --action=change
   ```

4. **Automated deployment via dotfiles**:
   The master installer (`~/dotfiles/install.sh`) automatically configures `/etc/udev/rules.d/70-edgepad.rules` and `/etc/modules-load.d/uinput.conf` using Polkit (`pkexec`) or sudo.

## Verification

Run EdgePad's built-in diagnostic tool as the regular desktop user:

```bash
edgepad doctor
```

Verify that all device and access checks report `ok`:

```text
Device
  ok    touchpad   /dev/input/eventX kind=touchpad ...
  ok    input      /dev/input/eventX can be opened by current user
  ok    uinput     /dev/uinput is readable and writable
Access
  ok    udev tags  /dev/input/eventX and /dev/uinput have current udev tags seat,uaccess
  ok    acl        user has rw ACL on /dev/input/eventX and /dev/uinput
Service
  ok    unit       edgepad.service is active (running)
```

## Related References
- [`references/config-paths.md`](../config-paths.md)
- [`01-xps-13-display-and-input.md`](01-xps-13-display-and-input.md)
