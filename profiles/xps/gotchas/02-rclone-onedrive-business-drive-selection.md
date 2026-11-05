# Rclone OneDrive Business/Education Missing Files (Drive Selection Gotcha)

- **ID**: `02-rclone-onedrive-business-drive-selection`
- **Category**: `System / Network`
- **Hardware / Target**: `Dell XPS 13 (xps) / Microsoft 365 Accounts`
- **Severity**: `Warning`

---

## Symptom
After connecting a Microsoft 365 or university account (e.g. `user@university.edu`) via `rclone config` and mounting the remote to `~/OneDrive`, the mounted directory appears virtually empty, showing only `__Root__.txt` and a `WebPartCache/` folder instead of user documents, projects, and files.

## Root Cause
Microsoft 365 tenants provision multiple SharePoint/OneDrive document libraries under each user's account:
1. `PersonalCacheLibrary` (`.../Lists/PersonalCacheLibrary`): An internal cache list storing SharePoint portal assets and cache files (`WebPartCache`).
2. `OneDrive` (`.../Documents`): The actual user's cloud document library containing their files.

When running `rclone config` or `rclone config create onedrive onedrive`, Microsoft Graph API often presents `PersonalCacheLibrary` as drive option 1. If option 1 is selected or accepted by default, rclone binds to the cache library rather than the user's primary document drive.

## Solution & Fix
1. Query Microsoft Graph API for the user's drives or inspect the available drives:
   ```bash
   python3 -c "
   import json, urllib.request
   with open('$HOME/.config/rclone/rclone.conf') as f:
       for line in f:
           if line.startswith('token ='):
               tok = json.loads(line.split('=', 1)[1].strip())['access_token']
               break
   req = urllib.request.Request('https://graph.microsoft.com/v1.0/me/drives', headers={'Authorization': f'Bearer {tok}'})
   with urllib.request.urlopen(req) as resp:
       for d in json.loads(resp.read().decode())['value']:
           print(f\"Name: {d.get('name')} | ID: {d.get('id')} | URL: {d.get('webUrl')}\")
   "
   ```
2. Locate the drive where `name == "OneDrive"` or the `webUrl` ends with `/Documents`.
3. In `~/.config/rclone/rclone.conf`, update the `drive_id`:
   ```ini
   [onedrive]
   type = onedrive
   token = { ... }
   drive_id = <ID_OF_ONEDRIVE_DOCUMENTS_DRIVE>
   drive_type = business
   ```
4. Restart the user service:
   ```bash
   systemctl --user restart onedrive.service
   ```

## Verification
Inspect the mount point:
```bash
ls -la ~/OneDrive
```
The user's actual document tree, personal folders, and files should now be visible and accessible on demand.

## Related References
- [`references/changelog.md`](../changelog.md)
