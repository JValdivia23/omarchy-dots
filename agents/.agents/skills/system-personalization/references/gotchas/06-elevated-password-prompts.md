# Interactive Password Authentication for Sudo Operations (`kitty -e`)

- **ID**: `06-elevated-password-prompts`
- **Category**: `System / Security`
- **Hardware / Target**: `Universal`
- **Severity**: `Critical`

---

## Symptom
An AI agent or automated background process attempts to execute a privileged command (such as `sudo pacman -S`, `sudo systemctl restart`, or modifying `/etc/` system files). The command either hangs indefinitely waiting for input, or immediately fails with:
```
sudo: a terminal is required to read the password; either use the -S option to read from standard input or configure an askpass helper
sudo: a password is required
```

## Root Cause
Subprocesses and background execution environments spawned by AI coding assistants or daemon tasks do not possess an allocated pseudo-terminal (TTY). When a command requires root elevation and the user does not have passwordless `sudo` configured for that binary, `sudo` attempts to prompt for a password via TTY. Because standard input is disconnected or closed, the prompt blocks or throws an authentication failure.

## Solution & Fix

### 1. Interactive Terminal Window (`kitty -e`)
Whenever a command requires interactive user authentication (e.g. entering a sudo password) or user confirmation, spawn an interactive terminal window with Kitty (or the active terminal):

```bash
kitty -e bash -c "sudo <command>; echo 'Done! Press Enter to close...'; read"
```

For package installations:
```bash
kitty -e bash -c "sudo pacman -S --needed <package_name>; echo 'Done! Press Enter to close...'; read"
```

This presents a clean, visible window on the user's desktop where they can safely inspect the command and type their credentials directly.

### 2. Graphical Polkit Authentication (`pkexec`)
If the command is invoked by a desktop GUI element or background automation where a graphical authentication agent (such as Quickshell Polkit or `lxqt-policykit`) is running, use `pkexec`:
```bash
pkexec <command>
```
> [!NOTE]
> Do NOT use `pkexec` when the user expects an interactive terminal stream or when running commands in standard CLI scripts. Use `sudo` via `kitty -e`.

## Verification
Launch a test privileged operation via Kitty:
```bash
kitty -e bash -c "sudo id; echo 'Authentication successful. Press Enter...'; read"
```
Verify that the terminal opens, prompts for credentials, displays the uid (`uid=0(root)`), and waits for confirmation before closing.

## Related References
- [`SKILL.md`](../../SKILL.md) Core Rule 4
- [`references/config-paths.md`](../config-paths.md)
