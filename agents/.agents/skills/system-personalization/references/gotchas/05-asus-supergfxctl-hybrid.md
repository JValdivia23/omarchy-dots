# ASUS ROG Dual GPU Switching (`supergfxctl`) & Power Management

- **ID**: `05-asus-supergfxctl-hybrid`
- **Category**: `Hardware / Power / Graphics`
- **Hardware / Target**: `ASUS ROG Laptops (e.g. Zephyrus G14, G15, M16, Strix)`
- **Severity**: `Warning`

---

## Symptom
1. Laptop battery drains rapidly (e.g. discharging at 20-30W even at idle).
2. The dedicated NVIDIA GPU remains powered on and warm, drawing 2-4W continuously even when no 3D games or graphic software are running.
3. 3D games or GPU rendering workloads launch on the low-power integrated AMD/Intel graphics by default, resulting in single-digit framerates.

## Root Cause
Dual-GPU laptops feature an energy-efficient integrated GPU (iGPU, such as AMD Radeon Vega/680M or Intel Iris Xe) alongside a power-hungry dedicated GPU (dGPU, NVIDIA GeForce). By default, Linux runs all Wayland display processes on the primary iGPU.

However, without proper power profile management and multiplexer coordination via `supergfxctl`, the NVIDIA GPU driver may remain in power state D0 rather than falling back to D3cold (0W complete power-off). Furthermore, Xorg or display managers may open DRM devices across both GPUs on boot, preventing the dGPU from sleeping.

## Solution & Fix

### 1. Set GPU Mode to Hybrid
`Hybrid` mode allows the dedicated GPU to enter dynamic D3cold sleep during desktop use while remaining immediately available for high-performance workloads:
```bash
# Verify supported modes
supergfxctl -s

# Set mode to Hybrid (may require logout/reboot)
supergfxctl -m Hybrid

# Check current active mode
supergfxctl -g
```

### 2. Configure Dynamic Power Management
Ensure `/etc/modprobe.d/nvidia-pm.conf` enables runtime power management:
```ini
options nvidia NVreg_DynamicPowerManagement=0x02
```
Verify the relevant systemd services are enabled:
```bash
sudo systemctl enable --now nvidia-suspend.service nvidia-hibernate.service nvidia-resume.service
```

### 3. Launching Applications on Dedicated GPU (PRIME Offload)
When running games or GPU-intensive tools, use `prime-run` or set the PRIME environment variables:
```bash
# Using prime-run wrapper:
prime-run steam
prime-run blender

# Or manual environment variables:
__NV_PRIME_RENDER_OFFLOAD=1 __GLX_VENDOR_LIBRARY_NAME=nvidia <command>
```

### 4. Prevent SDDM / Xorg from Holding dGPU Open
If Xorg or SDDM auto-detects the secondary GPU, create `/etc/X11/xorg.conf.d/10-primary-gpu.conf` to explicitly restrict Xorg to the integrated AMD GPU:
```xorg
Section "ServerFlags"
    Option "AutoAddGPU" "off"
endsection

Section "Device"
    Identifier "AMD"
    Driver "amdgpu"
    BusID "PCI:4:0:0"
EndSection
```

## Verification
1. Check NVIDIA GPU power draw when idle:
   ```bash
   cat /sys/bus/pci/devices/0000:01:00.0/power/runtime_status
   ```
   Should report `suspended`.
2. Check `nvidia-smi` when idle; no persistent desktop processes (like Xorg or Hyprland) should be attached to VRAM.

## Related References
- ASUS Linux Project: `https://asus-linux.org/`
- Supergfxctl Documentation: `https://gitlab.com/asus-linux/supergfxctl`
