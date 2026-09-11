# Privilege Escalation & Password Authentication in Omarchy Quattro

- **ID**: `03-elevated-password-prompts`
- **Category**: `System / Security`
- **Hardware / Target**: `Universal`
- **Severity**: `Critical`

---

## Symptom
An AI agent or automated background process attempts to execute a privileged command (such as package installations, modifying `/etc/`, or systemctl management). The command either hangs indefinitely waiting for input, or immediately fails with:
```
sudo: a terminal is required to read the password; either use the -S option to read from standard input or configure an askpass helper
sudo: a password is required
```

## Root Cause
Subprocesses and background execution environments spawned by AI coding assistants do not possess an interactive terminal (TTY). When a command requires root elevation and passwordless `sudo` is not configured, standard `sudo` blocks waiting for terminal input that never arrives.

## Solution: Omarchy Native Privilege Escalation

Omarchy Quattro establishes a clear privilege escalation protocol in [`~/.agents/skills/omarchy/SKILL.md`](../../../omarchy/SKILL.md#L84-L95):

### 1. Primary: Graphical Polkit Floating Prompt (`pkexec`)
For background commands launched by an agent or automated process where no TTY is available, use **`pkexec`**:
```bash
pkexec <command>
```
Omarchy’s Quickshell shell triggers its **built-in Polkit graphical agent**, displaying a sleek, centered **floating password dialog box** on the user's screen. The user types their password into the floating dialog, and the command completes seamlessly.

Example for package management or service restarts:
```bash
pkexec pacman -S --needed <package>
pkexec systemctl restart <service>
```

### 2. Secondary: Interactive Floating Terminal Presentation
When a command genuinely requires interactive terminal interaction or visual confirmation streams, use Omarchy's native presentation launcher:
```bash
omarchy-launch-floating-terminal-with-presentation "<command>"
```
Or universally via Wayland's terminal dispatcher:
```bash
setsid uwsm-app -- xdg-terminal-exec --app-id=org.omarchy.terminal --title=Omarchy -e bash -c "<command>; read -p 'Done! Press Enter to close...'"
```
Hyprland automatically intercepts windows with `--app-id=org.omarchy.terminal` and floats them centered on screen with the active Omarchy theme.

## Verification
Test the graphical floating prompt from your agent:
```bash
pkexec id
```
Verify that the themed floating password dialog appears on the desktop, accepts credentials, and returns `uid=0(root)`.

## Related References
- Built-in [`omarchy` Skill](../../../omarchy/SKILL.md) Section: *Privilege Escalation*
- [`SKILL.md`](../../SKILL.md) Core Rule 6
- [`references/config-paths.md`](../config-paths.md)

