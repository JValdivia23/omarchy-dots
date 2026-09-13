# Microsoft Surface Book 3 USB-C Charging & Power Delivery Quirks

- **ID**: `08-surface-book-usb-c-charging-quirks`
- **Category**: `Hardware / Power`
- **Hardware / Target**: `Microsoft Surface Book 3 (and Surface Book 2)`
- **Severity**: `Warning`

---

## Symptom
1. Plugging in a USB Type-C charger produces no charging indication (`cat /sys/class/power_supply/ADP1/online` remains `0`), even though the charger and cable function properly on other devices (like smartphones).
2. The charger connects briefly for ~350ms (`ADP1` toggles to `1`) and immediately cuts out (`ADP1` drops to `0`), repeating this disconnect/retry cycle every 1.5–2.0 seconds in an infinite loop ("charger hiccup" / negotiation flapping).
3. The issue frequently begins immediately after disconnecting external USB-C displays or DisplayPort Alt-Mode accessories (such as AR glasses or docks) that experienced bandwidth errors (`usb 3-2.1: Not enough bandwidth for altsetting 1`, `usb_set_interface failed (-28)`).

## Root Cause
This issue has two distinct root causes depending on the phase of failure:

### 1. Base Type-C / PD Controller Error State (Zero Detection)
On the Surface Book 3, the USB-C port is located on the keyboard base. When an alternate-mode device (like XREAL glasses or a failing monitor) floods the xHCI controller with bandwidth errors and is unplugged, the base Power Delivery (PD) PHY state machine can lock up in an alternate-mode or source role.
Under the USB Type-C specification, a charger (source) is strictly prohibited from applying $V_{\text{BUS}}$ until it detects an $R_d$ (5.1 kΩ pull-down) resistor on the Configuration Channel (CC) pins. If the base PD controller is hung, it fails to present $R_d$, and the charger provides 0 Volts. Standard reboots do not power cycle the base hardware because the tablet keeps the base bus energized.

### 2. Low-Wattage / Incompatible PD Profiles & High Initial Draw (The 350ms Hiccup)
The Surface Book 3 has **two separate batteries** (`BAT1` in the clipboard, `BAT2` in the base) and an Intel Core i5/i7 SoC with a 3000×2000 high-DPI display, drawing ~14W idle.
When both batteries are depleted (< 25%), the Surface charge controller initiates **maximum Constant Current fast-charging**, pulling **65W–75W** total:
- **Apple 61W Adapter (Model A1718)**: Only provides 20.3V @ 3.0A (60.9W), 9V @ 3.0A, and 5.2V @ 2.4A. It lacks a 15V rail and enforces a strict 3.0A Over-Current Protection (OCP) threshold. When the Surface demands >3.0A at ~350ms post-handshake, the Apple adapter trips OCP into foldback burst/hiccup mode.
- **Apple Adapter Latch Quirk**: Once an Apple USB-C power brick trips into hiccup mode, its high-voltage reservoir capacitor keeps the controller energized from the AC line; it will **never exit hiccup mode until unplugged from the wall for 60 seconds**.

## Solution & Fix

### Step 1: Force Base Hardware Cold Reset (Clears Port Deadlock)
Detach the clipboard to completely cut power to the keyboard base and its internal Genesys Logic USB hubs and PD controllers:
1. Unplug all cables from the USB-C port.
2. Press `SUPER + D` (or hold the hardware detach key) to release the DTX latch.
3. Lift the clipboard off the base.
4. Wait 10 seconds.
5. Firmly reseat the tablet back onto the base until both latches click.

### Step 2: Reset Apple / Smart USB-PD Bricks from the Wall
If the charger is pulsing on/off:
1. Unplug the charging brick completely from the AC wall outlet.
2. Disconnect the USB-C cable from both the brick and the laptop.
3. Wait **at least 60 seconds** to completely drain the primary capacitors.
4. Reconnect to the wall outlet first, then connect to the laptop.

### Step 3: Lower Power Draw (Charge While Suspended)
If using a 60W charger (like Apple A1718) on low battery (< 25%):
- Put the laptop into sleep mode (close lid or press the physical Power button once).
- In suspend mode, system draw drops to ~1W and the Surface EC throttles charging current below 3.0A, allowing 60W chargers to charge smoothly.
- Once both batteries reach > 40–50%, the charging controller transitions to Constant Voltage (lower current), and the laptop can be used while charging.

### Step 4: Use a Verified High-Wattage Supply
For continuous active use at low battery, use:
- The **original Surface Connect magnetic charger** (102W / 127W).
- Any standard **65W, 90W, or 100W USB-PD charger** supporting standard **15V / 3A** or **20V / 3.25A+** (e.g. Apple Model A1947/A2452 or standard PC USB-C chargers).

## Verification
Inspect real-time power supply status using sysfs:
```bash
cat /sys/class/power_supply/ADP1/online
cat /sys/class/power_supply/BAT1/status
cat /sys/class/power_supply/BAT2/status
```
Confirm:
- `ADP1` reports `1` steadily (not toggling between `0` and `1`).
- Both `BAT1` and `BAT2` report `Charging` (or `Full`).

## Related References
- [`04-surface-dtx-tablet-detach.md`](04-surface-dtx-tablet-detach.md)
- [`references/hardware.md`](../hardware.md)
