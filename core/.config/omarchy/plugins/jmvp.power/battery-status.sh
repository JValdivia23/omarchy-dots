#!/bin/bash
set -euo pipefail

# jmvp.power battery status: supports single and multi-battery setups (Surface Book, ThinkPad, etc.)
shell_output=false
case "${1:-}" in
  "") ;;
  --shell) shell_output=true ;;
  *)
    echo "Usage: battery-status.sh [--shell]" >&2
    exit 2
    ;;
esac

power_supply_path="${OMARCHY_POWER_SUPPLY_PATH:-/sys/class/power_supply}"
is_surface=false
if grep -qi "surface" /sys/devices/virtual/dmi/id/product_name 2>/dev/null; then
  is_surface=true
fi

# Detect AC online
ac_online=false
for supply in "$power_supply_path"/*; do
  [[ -r "$supply/type" ]] || continue
  [[ $(<"$supply/type") == "Mains" ]] || continue
  [[ -r "$supply/online" ]] || continue
  if [[ $(<"$supply/online") == "1" ]]; then
    ac_online=true
    break
  fi
done

# Read UPower DisplayDevice if available
display_info=$(upower -i /org/freedesktop/UPower/devices/DisplayDevice 2>/dev/null || true)
dd_percentage=$(awk '/percentage/ { print int($2); exit }' <<<"$display_info")
dd_time_remaining=$(awk '/time to (empty|full)/ {
  value = $4
  unit = $5
  if (unit ~ /^minute/) {
    printf "%dm", int(value)
  } else {
    hours = int(value)
    minutes = int((value - hours) * 60)
    if (minutes > 0) {
      printf "%dh %dm", hours, minutes
    } else {
      printf "%dh", hours
    }
  }
  exit
}' <<<"$display_info")
dd_state=$(awk '/state/ { print $2; exit }' <<<"$display_info")

# Scan all present batteries
declare -a bats=()
for bpath in "$power_supply_path"/BAT*; do
  [[ -d "$bpath" ]] || continue
  if [[ -r "$bpath/present" ]]; then
    [[ $(<"$bpath/present") == "1" ]] || continue
  fi
  bats+=("$bpath")
done

bat_count=${#bats[@]}
if (( bat_count == 0 )); then
  exit 0
fi

total_energy_now=0
total_energy_full=0
total_power_now=0
total_cycles=0
active_discharging=false
active_charging=false

declare -a out_lines=()

for ((i=0; i<bat_count; i++)); do
  bpath="${bats[$i]}"
  bname=$(basename "$bpath")
  idx=$((i+1))

  friendly_name="Battery $idx"
  if [[ "$is_surface" == "true" ]]; then
    if [[ "$bname" == "BAT1" ]]; then
      friendly_name="Tablet"
    elif [[ "$bname" == "BAT2" ]]; then
      friendly_name="Base"
    fi
  fi

  cap=$(cat "$bpath/capacity" 2>/dev/null || echo "0")
  stat=$(cat "$bpath/status" 2>/dev/null || echo "Unknown")
  cyc=$(cat "$bpath/cycle_count" 2>/dev/null || echo "")

  enow=$(cat "$bpath/energy_now" 2>/dev/null || echo "0")
  efull=$(cat "$bpath/energy_full" 2>/dev/null || echo "0")
  pnow=$(cat "$bpath/power_now" 2>/dev/null || echo "0")

  if (( pnow < 200000 )); then
    if [[ "$ac_online" == "true" ]]; then
      if (( cap >= 99 )); then
        stat="Fully charged"
      else
        stat="Holding"
      fi
    else
      stat="Holding"
    fi
  elif [[ "$stat" == "Unknown" || -z "$stat" ]]; then
    upstat=$(awk '/state:/ { print $2; exit }' <<<"$(upower -i "/org/freedesktop/UPower/devices/battery_$bname" 2>/dev/null || true)")
    if [[ "$upstat" == "pending-charge" ]]; then
      stat="Holding"
    elif [[ -n "$upstat" && "$upstat" != "unknown" ]]; then
      stat="$upstat"
    else
      stat="Holding"
    fi
  fi

  if [[ $stat =~ [Dd]ischarging ]]; then
    active_discharging=true
  elif [[ $stat =~ [Cc]harging ]]; then
    active_charging=true
  fi

  total_energy_now=$((total_energy_now + enow))
  total_energy_full=$((total_energy_full + efull))
  total_power_now=$((total_power_now + pnow))
  if [[ -n "$cyc" && "$cyc" =~ ^[0-9]+$ ]]; then
    total_cycles=$((total_cycles + cyc))
  fi

  p_wh=$(awk -v enow="$enow" -v efull="$efull" 'BEGIN { printf "%.1f / %.1f Wh", enow/1000000, efull/1000000 }')
  p_rate=$(awk -v pnow="$pnow" 'BEGIN {
    r = sprintf("%.1f", pnow/1000000)
    sub(/\.0$/, "", r)
    print r "W"
  }')

  out_lines+=("bat${idx}_id	$bname")
  out_lines+=("bat${idx}_name	$friendly_name")
  out_lines+=("bat${idx}_pct	${cap}%")
  out_lines+=("bat${idx}_raw_pct	${cap}")
  out_lines+=("bat${idx}_state	$stat")
  out_lines+=("bat${idx}_energy	$p_wh")
  out_lines+=("bat${idx}_rate	$p_rate")
  [[ -n "$cyc" ]] && out_lines+=("bat${idx}_cycles	$cyc")
done

# Calculate total percentage and capacity directly from sysfs (immune to UPower DisplayDevice glitches)
if (( total_energy_full > 0 )); then
  tot_pct=$((total_energy_now * 100 / total_energy_full))
  (( tot_pct > 100 )) && tot_pct=100
else
  tot_pct=0
fi

tot_capacity=$(awk -v efull="$total_energy_full" 'BEGIN { printf "%d", (efull/1000000) + 0.5 }')
tot_rate=$(awk -v pnow="$total_power_now" 'BEGIN {
  r = sprintf("%.1f", pnow/1000000)
  sub(/\.0$/, "", r)
  print r
}')

# Overall state
final_state="unknown"
if [[ "$active_discharging" == "true" ]]; then
  final_state="discharging"
elif [[ "$active_charging" == "true" ]]; then
  final_state="charging"
elif [[ "$ac_online" == "true" ]]; then
  if (( tot_pct >= 99 )); then
    final_state="fully-charged"
  else
    final_state="holding"
  fi
else
  final_state="discharging"
fi

# -------------------------------------------------------------
# 2-Minute (24-Sample) Rolling Average Ring Buffer
# -------------------------------------------------------------
history_dir="/run/user/$(id -u)/omarchy"
mkdir -p "$history_dir"
history_file="$history_dir/battery_samples"

now=$(date +%s)
echo -e "$now\t$total_power_now\t$total_energy_now\t$final_state" >> "$history_file"

# Prune entries older than 125 seconds or beyond 24 samples
if [[ -f "$history_file" ]]; then
  awk -v cutoff="$((now - 125))" '$1 >= cutoff' "$history_file" | tail -n 24 > "$history_file.tmp"
  mv "$history_file.tmp" "$history_file"
fi

# Compute rolling average power and smoothed time to empty / full
calc_result=$(awk \
  -v curr_state="$final_state" \
  -v enow="$total_energy_now" \
  -v efull="$total_energy_full" \
  -v inst_p="$total_power_now" '
$4 == curr_state {
  count++
  sum_p += $2
}
END {
  if (count == 0) {
    avg_p = inst_p
    count = 1
  } else {
    avg_p = sum_p / count
  }

  avg_w = sprintf("%.1f", avg_p / 1000000)
  sub(/\.0$/, "", avg_w)

  time_str = ""
  if (avg_p > 100000) {
    if (curr_state == "discharging") {
      minutes = int((enow / avg_p) * 60)
    } else if (curr_state == "charging") {
      minutes = int(((efull - enow) / avg_p) * 60)
    } else {
      minutes = 0
    }

    if (minutes > 0) {
      if (minutes < 60) {
        time_str = sprintf("%dm", minutes)
      } else {
        h = int(minutes / 60)
        m = minutes % 60
        if (m > 0) {
          time_str = sprintf("%dh %dm", h, m)
        } else {
          time_str = sprintf("%dh", h)
        }
      }
    }
  }
  printf "%d\t%s\t%s\n", count, avg_w, time_str
}
' "$history_file")

IFS=$'\t' read -r sample_count avg_power_rate smoothed_time_remaining <<<"$calc_result"

if [[ $shell_output == "true" ]]; then
  printf 'percentage\t%s\n' "${tot_pct}%"
  printf 'state\t%s\n' "$final_state"
  printf 'rate\t%s\n' "${avg_power_rate}W (avg)"
  printf 'inst_rate\t%s\n' "${tot_rate}W"
  printf 'avg_rate\t%s\n' "${avg_power_rate}W"
  printf 'size\t%s\n' "${tot_capacity}Wh"
  printf 'time\t%s\n' "$smoothed_time_remaining"
  printf 'sample_count\t%s\n' "$sample_count"
  printf 'cycles\t%s\n' "$total_cycles"
  printf 'bat_count\t%s\n' "$bat_count"
  for line in "${out_lines[@]}"; do
    printf '%s\n' "$line"
  done
  exit 0
fi

# Pretty text mode
if (( bat_count > 1 )); then
  details=""
  for ((i=1; i<=bat_count; i++)); do
    b_name=$(printf '%s\n' "${out_lines[@]}" | awk -F'\t' -v k="bat${i}_name" '$1 == k { print $2 }')
    b_pct=$(printf '%s\n' "${out_lines[@]}" | awk -F'\t' -v k="bat${i}_pct" '$1 == k { print $2 }')
    b_stat=$(printf '%s\n' "${out_lines[@]}" | awk -F'\t' -v k="bat${i}_state" '$1 == k { print $2 }')
    details+="${b_name}: ${b_pct} (${b_stat})  "
  done
  echo "Total: ${tot_pct}%  ·  ${smoothed_time_remaining:-—} left  ·  ${avg_power_rate}W avg (${tot_rate}W now) / ${tot_capacity}Wh  [${details%  }]"
else
  echo "Battery ${tot_pct}%  ·  ${smoothed_time_remaining:-—} left  ·  ${avg_power_rate}W avg / ${tot_capacity}Wh"
fi
