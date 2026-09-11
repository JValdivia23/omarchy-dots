# LocalSend Discovery & Transfer Blocked by UFW Firewall

- **ID**: `08-localsend-ufw-firewall`
- **Category**: `Networking / Firewall`
- **Hardware / Target**: `Universal (Arch Linux / CachyOS / Omarchy)`
- **Severity**: `Warning`

---

## Symptom
LocalSend is installed and running, but other devices on the same Wi-Fi/LAN cannot discover this machine, or file transfer requests fail to connect.

## Root Cause
UFW (Uncomplicated Firewall) is enabled by default on Omarchy and CachyOS systems (`ufw.service`), which blocks incoming unsolicited network connections by default. LocalSend uses port `53317` (TCP and UDP) for LAN peer discovery broadcasts and file payload transfers. Without explicit firewall exceptions, all incoming discovery packets and file transfers are dropped.

## Solution & Fix
Allow LocalSend's port `53317` through UFW for both TCP and UDP traffic:

```bash
# Allow LocalSend discovery and transfer ports
sudo ufw allow 53317/tcp comment 'LocalSend TCP'
sudo ufw allow 53317/udp comment 'LocalSend UDP'

# Reload firewall rules to apply immediately
sudo ufw reload
```

> [!NOTE]
> When executing firewall modifications from an automated script or background tool, follow [Gotcha 06](06-elevated-password-prompts.md) to launch an interactive terminal (`kitty -e bash -c "sudo ufw ...; read"`) for password authentication.

## Verification
1. Check UFW status to verify rules are active:
   ```bash
   sudo ufw status verbose
   ```
2. Open LocalSend on another mobile phone, tablet, or PC on the same Wi-Fi network and verify this machine appears in the "Nearby Devices" list.
3. Send a test file to verify bidirectional transfer.

## Related References
- [`references/config-paths.md`](../config-paths.md)
- [`06-elevated-password-prompts.md`](06-elevated-password-prompts.md)
