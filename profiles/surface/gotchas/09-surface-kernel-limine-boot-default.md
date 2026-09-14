# Surface Kernel Default Boot Order in Limine Bootloader

- **ID**: `09-surface-kernel-limine-boot-default`
- **Category**: `Hardware / System`
- **Hardware / Target**: `Microsoft Surface (Surface Book 3)`
- **Severity**: `Warning`

---

## Symptom
Upon system reboot, the machine boots into the generic Arch Linux kernel (`linux`) instead of the dedicated Surface kernel (`linux-surface`). While the system boots normally, critical Surface hardware functions fail to operate:
- Touchscreen and pen input are completely unresponsive (`iptsd` fails to bind).
- Surface DTX tablet detachment does not function (`surface-dtx-daemon` requires Surface SAM driver).
- Battery percentage readings are inaccurate or only show a single battery instead of clipboard + base batteries.
- Dedicated Surface hardware buttons (volume rocker, power button events) may misbehave.

## Root Cause
Omarchy Quattro configures the Limine bootloader via `limine-entry-tool`. By default, `/etc/limine-entry-tool.d/omarchy-defaults.conf` specifies the boot order wildcard:
```bash
BOOT_ORDER="*, *fallback, Snapshots"
```
When both `linux` (vanilla Arch kernel) and `linux-surface` are installed, the generic `*` pattern resolves in alphabetical order, placing `linux` before `linux-surface`. Because Limine defaults to entry #1 in the absence of an explicit override, `linux` is automatically booted on reboot unless the user manually intervenes in the boot menu.

## Solution & Fix

Following Omarchy's upstream kernel prioritization pattern (such as Dell XPS Panther Lake), create a late-sorting Limine drop-in configuration to prioritize `linux-surface`:

1. Create `/etc/limine-entry-tool.d/zz-surface-kernel.conf`:
   ```bash
   # Prioritize Surface kernel as default boot entry in Limine bootloader
   BOOT_ORDER="linux-surface*, *, *fallback, Snapshots"
   ```
   *(Note: Keeping `*` after `linux-surface*` ensures the vanilla `linux` kernel remains accessible as a secondary fallback entry in the boot menu).*

2. Rebuild the Unified Kernel Images (UKIs) and regenerate Limine configuration:
   ```bash
   pkexec limine-update
   ```

3. Ensure it is part of the automated Surface profile setup in `profiles/surface/setup.sh`.

## Verification
Inspect the boot menu tree to ensure `linux-surface` is the first entry:
```bash
/usr/lib/limine/limine-entry-tool --tree
```
Expected output:
```text
Omarchy
├─ linux-surface
├─ linux
└─ Snapshots
```

## Related References
- [`04-surface-dtx-tablet-detach.md`](04-surface-dtx-tablet-detach.md)
- [`03-surface-scaling-and-touch.md`](03-surface-scaling-and-touch.md)
- [`references/config-paths.md`](../config-paths.md)
- [`profiles/surface/setup.sh`](../../../../profiles/surface/setup.sh)
