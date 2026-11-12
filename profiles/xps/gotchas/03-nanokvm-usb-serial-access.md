# Grant Access to Only the Attached NanoKVM-USB Serial Interface

- **ID**: `03-nanokvm-usb-serial-access`
- **Category**: Input / System
- **Hardware / Target**: Sipeed NanoKVM-USB, serial `5C82073583`, with the XPS as controller
- **Severity**: Warning

---

## Symptom

The NanoKVM's HDMI picture can be captured, but the controlling user cannot open its keyboard/mouse serial interface. This unit appears as `/dev/ttyACM0`, not the `/dev/ttyUSBx` used in generic upstream troubleshooting examples.

## Root Cause

The serial node was owned by `root:uucp`, mode `0660`, without a user ACL. The active user was not in `uucp`. Video already had a session-user ACL, so a working picture did not imply working serial permissions.

The native `cdc_acm` driver was already bound to USB ID `1a86:55d3`. Replacing CH34x drivers, uninstalling accessibility software, or granting world access was not justified by the observed failure.

## Solution & Fix

This is a **device-specific permission**, not a universal user preference or an XPS-wide serial-access policy. After explicit user approval, install `/etc/udev/rules.d/70-nanokvm-usb.rules` as `root:root`, mode `0644`:

```udev
# Grant the active local desktop user access to this NanoKVM-USB serial interface only.
SUBSYSTEM=="tty", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="55d3", ATTRS{serial}=="5C82073583", TAG+="uaccess"
```

The serial number restricts the rule to this unit. The `70-` filename ensures its tag exists before `73-seat-late.rules` applies the active local user's ACL. Do not use `chmod 777` or add broad serial-device group membership as a substitute.

After verifying the device identity, activate only its serial-node event:

```bash
SERIAL=/dev/serial/by-id/usb-1a86_USB_Single_Serial_5C82073583-if00
udevadm verify /etc/udev/rules.d/70-nanokvm-usb.rules
pkexec udevadm control --reload-rules
pkexec udevadm trigger --action=change "/sys/class/tty/$(basename "$(readlink -f "$SERIAL")")"
udevadm settle --timeout=10
```

Reconnecting the HOST cable after reloading rules is an alternative. Never trigger all devices unnecessarily. Headless/SSH-only use needs a separately reviewed policy because `uaccess` follows the active local seat.

## Verification

On 2026-11-11, `udevadm verify` passed; the node gained `user:jairo:rw-`; and effective read/write access changed from false to true without reconnecting or rebooting. Group ownership and mode `0660` remained unchanged.

```bash
getfacl --absolute-names /dev/serial/by-id/usb-1a86_USB_Single_Serial_5C82073583-if00
python - <<'PY'
import os
p = '/dev/serial/by-id/usb-1a86_USB_Single_Serial_5C82073583-if00'
print('Readable:', os.access(p, os.R_OK))
print('Writable:', os.access(p, os.W_OK))
PY
```

These checks do not open the serial port or send control bytes. End-to-end target keyboard/mouse operation remains untested. Video capture separately showed the target desktop at 1920 × 1080; device-reported zero DV timings did not mean the signal was absent.

## Related References

- [System configuration and privilege conventions](../../../agents/.agents/skills/system-personalization/references/config-paths.md)
- [Sipeed NanoKVM-USB quick start](https://wiki.sipeed.com/hardware/en/kvm/NanoKVM_USB/quick_start.html)
- [Sipeed NanoKVM-USB FAQ](https://wiki.sipeed.com/hardware/en/kvm/NanoKVM_USB/faq.html)
- Local setup and troubleshooting: `~/Work/nanoKVM/README.md` and `~/Work/nanoKVM/docs/troubleshooting.md`.
