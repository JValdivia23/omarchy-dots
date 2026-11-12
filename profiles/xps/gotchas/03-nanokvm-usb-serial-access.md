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

These permission checks do not open the serial port or send control bytes. Video capture separately showed the target desktop at 1920 × 1080; device-reported zero DV timings did not mean the signal was absent.

### Follow-up: approved target input and terminal verification

Later on 2026-11-11, the user separately approved mouse and terminal tests. A temporary standard-library Python helper followed Sipeed's 57600-baud protocol, validated packet checksums, and used only `GET_INFO` and ordinary keyboard/mouse commands. The device reported the target USB connection present.

Initial acknowledged input produced no visible terminal. An absolute pointer move into the captured desktop, followed by Super + Enter, opened Kitty on the CachyOS/ROG Zephyrus G14 target. This was consistent with focus initially being on another display; the monitor topology was not queried. Do not type blindly when acknowledgements arrive but the capture is unchanged.

The command `echo nanokvm-terminal-ok` was entered without Enter, checked in a capture, then executed. A subsequent capture showed `nanokvm-terminal-ok` and a fresh fish prompt. This initial test verified pointer motion, the terminal shortcut, typing, and Enter. No target packages or system configuration were changed.

The temporary helper has been superseded by the permanent project-local `~/Work/nanoKVM/kvmctl` and `nanokvm/` Python API. It requires no pip packages or service installation and exposes local JSON/Python interfaces, not a network listener. Input requires explicit `--send` / `allow_input=True`; typing never adds Enter. KVM serial data is HID control, not a target shell: read output from fresh captures, and release keys after each press.

The initial permanent tool passed 57 offline tests and real device checks for status, capture/OCR, left-click focus, keyboard/terminal input, scrolling up/down, explicit release, and bounded foreground preview. The visually inspected `echo nanokvm-cli-ready` returned the expected marker. Pointer visibility alone was sometimes inconclusive; a safe click visibly established focus. The persistent guide and capability limits are in `~/Work/nanoKVM/docs/cli.md` and `docs/verification.md`.

### Follow-up: native SSH and pre-boot display limits

The user explicitly approved a dedicated SSH repair key and a reboot with work saved. The target's existing sshd was already active/enabled. Its host fingerprint was compared with the public key printed on the KVM display before authentication; only one source-restricted public-key line was appended to the user's existing `authorized_keys`. The private key and pinned host file are under the controller's `~/.ssh/` with mode `0600`, not in source control. No server, password, sudo, or root-access policy was changed.

Use `~/Work/nanoKVM/targetssh 'reviewed command'` for native target stdout/exit status when Linux/networking are available. The project profile uses only the dedicated identity and a strict host-key alias/pin. The key's `from="10.0.0.217",restrict,pty` restriction is tied to the controller's current LAN address; do not silently remove it after a DHCP/network change.

An authorized `systemctl reboot --firmware-setup` from the active target console reached BIOS. **HDMI capture was black, while the user saw firmware on the built-in panel.** KVM F8 opened the boot menu, and Down/Enter navigation to the user-confirmed Limine entry returned to Linux. The boot ID changed, authenticated SSH returned, the one-shot firmware property cleared, and HDMI capture returned at the login/password screen. No boot-order, Secure Boot, firmware-image, or default settings were edited.

This is consistent with internal-versus-secondary display routing, but the exact cause was not independently established. It does **not** verify fully unattended pre-boot video. If firmware capture is black, require a trusted observer/photo and confirm the highlighted entry before selection; never blindly save/reset settings or force power off. SSH is unavailable in firmware, but works at the Linux login screen without unlocking the GUI. Leave that password prompt untouched unless the user authenticates privately.

The expanded suite has 62 passing offline tests. Other BIOS input modes, cold power-on Esc interception, other buttons/layouts, and USB-media boot are not claimed tested. See `~/Work/nanoKVM/docs/ssh-and-boot.md` for key paths, authentication restrictions, revocation guidance, and the exact boot-test scope.

## Related References

- [System configuration and privilege conventions](../../../agents/.agents/skills/system-personalization/references/config-paths.md)
- [Sipeed NanoKVM-USB quick start](https://wiki.sipeed.com/hardware/en/kvm/NanoKVM_USB/quick_start.html)
- [Sipeed NanoKVM-USB FAQ](https://wiki.sipeed.com/hardware/en/kvm/NanoKVM_USB/faq.html)
- Local setup and troubleshooting: `~/Work/nanoKVM/README.md` and `~/Work/nanoKVM/docs/troubleshooting.md`.
