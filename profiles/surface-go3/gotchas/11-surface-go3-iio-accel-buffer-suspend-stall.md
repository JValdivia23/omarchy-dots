# Surface Go 3 Intel ISH `accel_3d` IIO Buffer Stall After `s2idle` Resume

- **ID**: `11-surface-go3-iio-accel-buffer-suspend-stall`
- **Category**: `Hardware / Display / Power`
- **Hardware / Target**: `Microsoft Surface Go 3 (surface-go3)`
- **Severity**: `Warning`

---

## Symptom

After waking the Surface Go 3 from `s2idle` suspend in Denial Mobile, automatic screen rotation stops working and the display remains stuck in its pre-suspend orientation (e.g. `transform: "90"` / `"left-up"`):

- `journalctl -u steinerd-iio-bridge` logs:
  `WARNING ClaimAccelerometer failed: g-io-error-quark: Timeout was reached (24)`
- `monitor-sensor` prints `+++ iio-sensor-proxy appeared` and hangs indefinitely; `busctl call net.hadess.SensorProxy /net/hadess/SensorProxy net.hadess.SensorProxy ClaimAccelerometer` times out.
- `/sys/bus/iio/devices/iio:device2/buffer/enable` stays `1` while `buffer/data_available` stays `0`, even though reading `in_accel_{x,y,z}_raw` directly via sysfs returns fresh live accelerometer values.

## Root Cause

1. Upstream `/usr/lib/udev/rules.d/80-iio-sensor-proxy.rules` tags the Intel ISH `hid-sensor-accel-3d` device (`accel_3d`) with both `iio-poll-accel` and `iio-buffer-accel`, and `iio-sensor-proxy` (`3.9-1`) prefers `iio-buffer-accel`.
2. When Denial releases orientation before sleep and immediately re-claims it at `PM: suspend exit`, `iio-sensor-proxy` enables the IIO trigger/ring buffer (`buffer/enable = 1`) and defers replying to `ClaimAccelerometer()` until the first buffered sample arrives. On Intel ISH (`intel_ish_ipc` / `hid-sensor-trigger`), the ring buffer can stall after `s2idle` resume (`data_available = 0`), wedging `iio-sensor-proxy`'s claim handler permanently while sysfs `in_accel_*_raw` remains functional.
3. Previously, `steinerd-iio-bridge` issued a blocking 5-second `call_sync("ClaimAccelerometer")` and never retried after a timeout, leaving `accel_claimed = False` even though Denial held an active orientation claim.

## Solution & Fix

1. **Force `iio-poll-accel` for `accel_3d` via udev rule** (`/etc/udev/rules.d/81-surface-go3-iio-poll.rules`, deployed by `profiles/surface-go3/setup.sh`):

```udev
# Surface Go 3 Intel ISH hid-sensor-accel-3d IIO ring buffer stalls after s2idle suspend/resume,
# wedging iio-sensor-proxy ClaimAccelerometer(). Force reliable sysfs polling instead.
SUBSYSTEM=="iio", ATTR{name}=="accel_3d", ENV{IIO_SENSOR_PROXY_TYPE}="iio-poll-accel"
```

2. **Use async D-Bus calls with automatic backoff retry in `profiles/surface-go3/system/steinerd-iio-bridge`**:
   - Replaced blocking `call_sync` with async `ClaimAccelerometer`/`ReleaseAccelerometer` and exponential backoff retries (`2s` -> `4s` -> `8s` -> `10s`) whenever claimants exist and a claim fails or times out.
3. **Apply live via `setup.sh`**:

```bash
pkexec bash ~/dotfiles/profiles/surface-go3/setup.sh
```

`setup.sh` reloads udev rules, stops `iio-sensor-proxy.service`, clears any stuck `accel_3d` `buffer/enable`, triggers udev for `accel_3d`, and restarts `iio-sensor-proxy.service` and `steinerd-iio-bridge.service`.

## Verification

```bash
udevadm verify /etc/udev/rules.d/81-surface-go3-iio-poll.rules
udevadm info -q property -p /sys/bus/iio/devices/iio:device2 | grep IIO_SENSOR_PROXY_TYPE
cat /sys/bus/iio/devices/iio:device2/buffer/enable
busctl get-property org.steinerd /org/steinerd org.steinerd.Sensors1 HasOrientation Orientation
timeout 2 monitor-sensor
denialctl --json outputs | grep -E '"transform"|"logical_'
```

Expected results:
- `IIO_SENSOR_PROXY_TYPE=iio-poll-accel` and `buffer/enable` is `0`.
- `monitor-sensor` immediately reports `=== Has accelerometer (orientation: ...)`.
- `org.steinerd` reports live orientation and `denialctl --json outputs` reflects physical tablet rotation.

## Related References
- [`profiles/surface-go3/setup.sh`](../../../profiles/surface-go3/setup.sh)
- [`profiles/surface-go3/system/steinerd-iio-bridge`](../../../profiles/surface-go3/system/steinerd-iio-bridge)
- [`references/changelog.md`](../changelog.md)
