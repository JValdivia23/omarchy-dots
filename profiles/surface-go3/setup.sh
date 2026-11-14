#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "==> Setting up Surface Go 3 profile..."
echo "    Surface Go 3 uses ELAN9038 I2C-HID touch/stylus, kernel surface_aggregator modules, and CDC-MBIM LTE."

run_root() {
    if (( EUID == 0 )); then
        "$@"
    else
        sudo "$@"
    fi
}

install_root_file() {
    local mode="$1"
    local dest="$2"
    local tmp
    tmp="$(mktemp)"
    cat > "$tmp"
    run_root install -d -m 755 "$(dirname "$dest")"
    if [ ! -f "$dest" ] || ! cmp -s "$tmp" "$dest"; then
        echo "--> Installing $dest..."
        run_root install -m "$mode" "$tmp" "$dest"
        rm -f "$tmp"
        return 0
    fi
    rm -f "$tmp"
    return 1
}

# Deploy Surface Go 3 LTE (045e:09a5) initialization workaround:
# 1. NCM rx_max/tx_max must be 16383 before MBIM OPEN (16384 causes OPEN Failure 0x02).
# 2. If physical SIM (slot 1) and eUICC (slot 2) are both active, power off slot 2 so
#    ModemManager 1.24 does not loop on "SIM identifier has changed" reprobing.
udev_changed=false
systemd_changed=false
thermald_changed=false
rapl_changed=false
pstore_changed=false

install_root_file 755 /usr/local/bin/surface-go3-lte-init <<'EOF' || true
#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-full}"
QMICLI_BIN="$(command -v qmicli || true)"

for usbdev in /sys/bus/usb/devices/*; do
    [ -f "$usbdev/idVendor" ] && [ -f "$usbdev/idProduct" ] || continue
    [ "$(cat "$usbdev/idVendor" 2>/dev/null || true)" = "045e" ] || continue
    [ "$(cat "$usbdev/idProduct" 2>/dev/null || true)" = "09a5" ] || continue

    for ncm_dir in "$usbdev"/*:1.*/net/*/cdc_ncm; do
        [ -d "$ncm_dir" ] || continue
        for attr in rx_max tx_max; do
            [ -w "$ncm_dir/$attr" ] && echo 16383 > "$ncm_dir/$attr" 2>/dev/null || true
        done
    done

    [ "$MODE" = "--net-only" ] && continue
    [ -n "$QMICLI_BIN" ] || continue

    wdm_dev=""
    for wdm in "$usbdev"/*:1.*/usbmisc/cdc-wdm*; do
        [ -e "$wdm" ] || continue
        wdm_dev="/dev/$(basename "$wdm")"
        break
    done
    [ -c "$wdm_dev" ] || continue

    slot_status="$("$QMICLI_BIN" -d "$wdm_dev" --device-open-mbim --uim-get-slot-status 2>/dev/null || true)"
    if printf '%s\n' "$slot_status" | awk '
        /Physical slot 1:/ { s=1; next }
        /Physical slot 2:/ { s=2; next }
        /Physical slot [0-9]+:/ { s=0; next }
        s==1 && /Card status: present/ { s1=1 }
        s==2 && /Card status: present/ { s2=1 }
        s==2 && /Is eUICC: yes/ { e2=1 }
        END { exit !(s1 && s2 && e2) }
    '; then
        "$QMICLI_BIN" -d "$wdm_dev" --device-open-mbim --uim-sim-power-off=2 >/dev/null 2>&1 || true
    fi
done
EOF

if install_root_file 644 /etc/udev/rules.d/78-surface-go3-lte.rules <<'EOF'; then
# Ensure Surface Go 3 LTE (045e:09a5) uses 16383-byte NCM buffers on bind/reset
ACTION=="add|change", SUBSYSTEM=="net", ATTRS{idVendor}=="045e", ATTRS{idProduct}=="09a5", RUN+="/usr/local/bin/surface-go3-lte-init --net-only"
EOF
    udev_changed=true
fi

if install_root_file 644 /etc/systemd/system/ModemManager.service.d/surface-go3-lte.conf <<'EOF'; then
[Service]
ExecStartPre=-/usr/local/bin/surface-go3-lte-init
EOF
    systemd_changed=true
fi

# Deploy Surface Go 3 OEM-grounded thermal/RAPL configuration & crash pstore capture:
# 1. Load coretemp, x86_pkg_temp_thermal, intel_rapl_msr synchronously before thermald starts.
# 2. Cap RAPL PL1=10W / PL2=20W (matching Surface Go 3 Windows SMF Balanced ceiling vs Linux 15W/24W).
# 3. Configure thermald passive/max trips for SKIN (TZ04: 48C/54C), Battery (TZ05: 48C/56C),
#    SEN1-3 (TZ01-03: 58C), and x86_pkg_temp (78C/88C).
# 4. Enable efi_pstore across reboots via Limine UKI drop-in and systemd-pstore.
install_root_file 644 /etc/modules-load.d/surface-go3-thermal.conf <<'EOF' || true
coretemp
x86_pkg_temp_thermal
intel_rapl_msr
EOF

if install_root_file 644 /etc/udev/rules.d/80-surface-go3-rapl.rules <<'EOF'; then
# Cap Surface Go 3 (Core i3-10100Y, 5W TDP) RAPL limits to Windows SMF Balanced ceiling (PL1=10W, PL2=20W)
ACTION=="add", SUBSYSTEM=="powercap", KERNEL=="intel-rapl:0", ATTR{name}=="package-0", ATTR{constraint_0_power_limit_uw}="10000000", ATTR{constraint_1_power_limit_uw}="20000000"
EOF
    udev_changed=true
    rapl_changed=true
fi

if install_root_file 644 /etc/thermald/thermal-conf.xml <<'EOF'; then
<?xml version="1.0"?>
<ThermalConfiguration>
  <Platform>
    <Name>Microsoft Surface Go 3</Name>
    <ProductName>Surface Go 3</ProductName>
    <Preference>QUIET</Preference>

    <ThermalSensors>
      <ThermalSensor>
        <Type>SEN1</Type>
        <Path>/sys/devices/LNXSYSTM:00/LNXSYBUS:00/PNP0A08:00/device:1a/LNXTHERM:00/thermal_zone/temp</Path>
        <AsyncCapable>0</AsyncCapable>
      </ThermalSensor>
      <ThermalSensor>
        <Type>SEN2</Type>
        <Path>/sys/devices/LNXSYSTM:00/LNXSYBUS:00/PNP0A08:00/device:1a/LNXTHERM:01/thermal_zone/temp</Path>
        <AsyncCapable>0</AsyncCapable>
      </ThermalSensor>
      <ThermalSensor>
        <Type>SEN3</Type>
        <Path>/sys/devices/LNXSYSTM:00/LNXSYBUS:00/PNP0A08:00/device:1a/LNXTHERM:02/thermal_zone/temp</Path>
        <AsyncCapable>0</AsyncCapable>
      </ThermalSensor>
      <ThermalSensor>
        <Type>SKIN</Type>
        <Path>/sys/devices/LNXSYSTM:00/LNXSYBUS:00/PNP0A08:00/device:1a/LNXTHERM:03/thermal_zone/temp</Path>
        <AsyncCapable>0</AsyncCapable>
      </ThermalSensor>
      <ThermalSensor>
        <Type>BAT0_THERM</Type>
        <Path>/sys/devices/LNXSYSTM:00/LNXSYBUS:00/PNP0A08:00/device:1a/LNXTHERM:04/thermal_zone/temp</Path>
        <AsyncCapable>0</AsyncCapable>
      </ThermalSensor>
    </ThermalSensors>

    <ThermalZones>
      <ThermalZone>
        <Type>SKIN</Type>
        <TripPoints>
          <TripPoint>
            <SensorType>SKIN</SensorType>
            <Temperature>48000</Temperature>
            <type>passive</type>
            <ControlType>SEQUENTIAL</ControlType>
            <CoolingDevice>
              <index>1</index>
              <type>rapl_controller</type>
              <influence>100</influence>
              <SamplingPeriod>2</SamplingPeriod>
            </CoolingDevice>
            <CoolingDevice>
              <index>2</index>
              <type>intel_pstate</type>
              <influence>50</influence>
              <SamplingPeriod>4</SamplingPeriod>
            </CoolingDevice>
          </TripPoint>
          <TripPoint>
            <SensorType>SKIN</SensorType>
            <Temperature>54000</Temperature>
            <type>max</type>
            <ControlType>PARALLEL</ControlType>
            <CoolingDevice>
              <index>1</index>
              <type>rapl_controller</type>
              <influence>100</influence>
              <SamplingPeriod>1</SamplingPeriod>
            </CoolingDevice>
            <CoolingDevice>
              <index>2</index>
              <type>intel_pstate</type>
              <influence>80</influence>
              <SamplingPeriod>2</SamplingPeriod>
            </CoolingDevice>
            <CoolingDevice>
              <index>3</index>
              <type>intel_powerclamp</type>
              <influence>60</influence>
              <SamplingPeriod>2</SamplingPeriod>
            </CoolingDevice>
          </TripPoint>
        </TripPoints>
      </ThermalZone>

      <ThermalZone>
        <Type>BAT0_THERM</Type>
        <TripPoints>
          <TripPoint>
            <SensorType>BAT0_THERM</SensorType>
            <Temperature>48000</Temperature>
            <type>passive</type>
            <ControlType>SEQUENTIAL</ControlType>
            <CoolingDevice>
              <index>1</index>
              <type>rapl_controller</type>
              <influence>100</influence>
              <SamplingPeriod>4</SamplingPeriod>
            </CoolingDevice>
          </TripPoint>
          <TripPoint>
            <SensorType>BAT0_THERM</SensorType>
            <Temperature>56000</Temperature>
            <type>max</type>
            <ControlType>PARALLEL</ControlType>
            <CoolingDevice>
              <index>1</index>
              <type>rapl_controller</type>
              <influence>100</influence>
              <SamplingPeriod>2</SamplingPeriod>
            </CoolingDevice>
            <CoolingDevice>
              <index>2</index>
              <type>intel_pstate</type>
              <influence>80</influence>
              <SamplingPeriod>2</SamplingPeriod>
            </CoolingDevice>
            <CoolingDevice>
              <index>3</index>
              <type>intel_powerclamp</type>
              <influence>60</influence>
              <SamplingPeriod>2</SamplingPeriod>
            </CoolingDevice>
          </TripPoint>
        </TripPoints>
      </ThermalZone>

      <ThermalZone>
        <Type>SEN1</Type>
        <TripPoints>
          <TripPoint>
            <SensorType>SEN1</SensorType>
            <Temperature>58000</Temperature>
            <type>passive</type>
            <ControlType>SEQUENTIAL</ControlType>
            <CoolingDevice>
              <index>1</index>
              <type>rapl_controller</type>
              <influence>100</influence>
              <SamplingPeriod>2</SamplingPeriod>
            </CoolingDevice>
            <CoolingDevice>
              <index>2</index>
              <type>intel_pstate</type>
              <influence>60</influence>
              <SamplingPeriod>4</SamplingPeriod>
            </CoolingDevice>
          </TripPoint>
        </TripPoints>
      </ThermalZone>

      <ThermalZone>
        <Type>SEN2</Type>
        <TripPoints>
          <TripPoint>
            <SensorType>SEN2</SensorType>
            <Temperature>58000</Temperature>
            <type>passive</type>
            <ControlType>SEQUENTIAL</ControlType>
            <CoolingDevice>
              <index>1</index>
              <type>rapl_controller</type>
              <influence>100</influence>
              <SamplingPeriod>2</SamplingPeriod>
            </CoolingDevice>
            <CoolingDevice>
              <index>2</index>
              <type>intel_pstate</type>
              <influence>60</influence>
              <SamplingPeriod>4</SamplingPeriod>
            </CoolingDevice>
          </TripPoint>
        </TripPoints>
      </ThermalZone>

      <ThermalZone>
        <Type>SEN3</Type>
        <TripPoints>
          <TripPoint>
            <SensorType>SEN3</SensorType>
            <Temperature>58000</Temperature>
            <type>passive</type>
            <ControlType>SEQUENTIAL</ControlType>
            <CoolingDevice>
              <index>1</index>
              <type>rapl_controller</type>
              <influence>100</influence>
              <SamplingPeriod>2</SamplingPeriod>
            </CoolingDevice>
            <CoolingDevice>
              <index>2</index>
              <type>intel_pstate</type>
              <influence>60</influence>
              <SamplingPeriod>4</SamplingPeriod>
            </CoolingDevice>
          </TripPoint>
        </TripPoints>
      </ThermalZone>

      <ThermalZone>
        <Type>cpu</Type>
        <TripPoints>
          <TripPoint>
            <SensorType>x86_pkg_temp</SensorType>
            <Temperature>78000</Temperature>
            <type>passive</type>
            <ControlType>SEQUENTIAL</ControlType>
            <CoolingDevice>
              <index>1</index>
              <type>rapl_controller</type>
              <influence>100</influence>
              <SamplingPeriod>1</SamplingPeriod>
            </CoolingDevice>
            <CoolingDevice>
              <index>2</index>
              <type>intel_pstate</type>
              <influence>50</influence>
              <SamplingPeriod>2</SamplingPeriod>
            </CoolingDevice>
          </TripPoint>
          <TripPoint>
            <SensorType>x86_pkg_temp</SensorType>
            <Temperature>88000</Temperature>
            <type>max</type>
            <ControlType>PARALLEL</ControlType>
            <CoolingDevice>
              <index>1</index>
              <type>rapl_controller</type>
              <influence>100</influence>
              <SamplingPeriod>1</SamplingPeriod>
            </CoolingDevice>
            <CoolingDevice>
              <index>2</index>
              <type>intel_pstate</type>
              <influence>80</influence>
              <SamplingPeriod>1</SamplingPeriod>
            </CoolingDevice>
            <CoolingDevice>
              <index>3</index>
              <type>intel_powerclamp</type>
              <influence>60</influence>
              <SamplingPeriod>2</SamplingPeriod>
            </CoolingDevice>
          </TripPoint>
        </TripPoints>
      </ThermalZone>
    </ThermalZones>
  </Platform>
</ThermalConfiguration>
EOF
    thermald_changed=true
fi

if install_root_file 644 /etc/systemd/system/thermald.service.d/surface-go3.conf <<'EOF'; then
[Unit]
Wants=systemd-modules-load.service
After=systemd-modules-load.service
EOF
    systemd_changed=true
    thermald_changed=true
fi

if install_root_file 644 /etc/limine-entry-tool.d/pstore.conf <<'EOF'; then
KERNEL_CMDLINE[default]+=" efi_pstore.pstore_disable=0"
EOF
    pstore_changed=true
fi

if [ "$udev_changed" = true ]; then
    echo "--> Reloading udev rules..."
    run_root udevadm control --reload-rules || true
fi

if [ "$systemd_changed" = true ]; then
    echo "--> Reloading systemd daemon..."
    run_root systemctl daemon-reload || true
fi

if [ "$rapl_changed" = true ] || { [ -r /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw ] && [ "$(cat /sys/class/powercap/intel-rapl:0/constraint_0_power_limit_uw 2>/dev/null || echo 0)" -gt 10000000 ]; }; then
    echo "--> Applying Surface Go 3 RAPL power limits (PL1=10W, PL2=20W)..."
    # Stop thermald first so it does not restore its previously cached 15W PL1 on exit
    if systemctl is-active --quiet thermald.service; then
        run_root systemctl stop thermald.service || true
    fi
    run_root udevadm trigger --subsystem-match=powercap --action=add || true
    run_root udevadm settle || true
fi

if [ "$pstore_changed" = true ] && command -v limine-update >/dev/null 2>&1; then
    echo "--> Rebuilding Limine UKI for efi_pstore..."
    run_root limine-update || true
fi

# Enable and start hardware services if available
if [ -f "$SCRIPT_DIR/services.txt" ]; then
    while IFS= read -r service || [ -n "$service" ]; do
        service="${service%%#*}"
        service="$(echo "$service" | xargs)"
        [ -z "$service" ] && continue
        echo "--> Checking service: $service"
        if systemctl is-active --quiet "$service"; then
            if [ "$systemd_changed" = true ] || { [ "$service" = "thermald.service" ] && [ "$thermald_changed" = true ]; }; then
                echo "    Restarting $service to apply changes..."
                run_root systemctl restart "$service" || true
            else
                echo "    $service is already active."
            fi
        elif systemctl list-unit-files "$service" &>/dev/null; then
            if systemctl is-enabled --quiet "$service" 2>/dev/null; then
                if [ "$service" = "systemd-pstore.service" ]; then
                    echo "    $service is enabled."
                else
                    echo "    Starting $service..."
                    run_root systemctl start "$service" || true
                fi
            else
                echo "    Enabling and starting $service..."
                run_root systemctl enable --now "$service" || true
            fi
        else
            echo "    Notice: $service unit not found on this system. Skipping."
        fi
    done < "$SCRIPT_DIR/services.txt"
fi

echo "==> Surface Go 3 profile setup complete."
