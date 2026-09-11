# How to Write a Gotcha in Omarchy Quattro

Comprehensive guide and standard operating procedure for discovering, troubleshooting, and documenting system quirks, compositor pitfalls, and hardware workarounds.

---

## 🎯 Purpose & Architecture

The **System Personalization Skill** uses a **Single-File Modular Gotchas** architecture. Rather than maintaining a single monolithic troubleshooting file that exhausts LLM context windows, each gotcha is maintained as an isolated, self-contained markdown document in `references/gotchas/`.

This design ensures:
1. **Targeted Agent Retrieval**: AI assistants only read the exact file relevant to their task.
2. **Clean Separation of Concerns**: Universal system guardrails remain decoupled from hardware-specific workarounds.
3. **Multi-Machine Portability**: Hardware-specific gotchas travel with their respective profile (`profiles/<profile>/gotchas/`) and are linked automatically during installation.

---

## 🧭 Universal vs. Profile Gotchas

When documenting an issue, determine its scope before creating the file:

| Scope | Location | Criteria & Examples |
|-------|----------|---------------------|
| **Universal Guardrails** | `agents/.agents/skills/system-personalization/references/gotchas/` | Applies to **all** machines running Omarchy Quattro. Examples: Hyprland Lua validation, `/usr/share/omarchy/` read-only rule, sudo interactive password authentication. |
| **Profile-Specific Gotchas** | `profiles/<profile>/gotchas/` | Applies **only** to specific hardware or machine families. Examples: Surface Book latch mechanism (`surface-dtx`), HiDPI integer scaling on 3:2 displays, convertible tablet virtual keyboards. |

> [!IMPORTANT]
> When adding a profile-specific gotcha in `profiles/<profile>/gotchas/`, `install.sh` will automatically symlink it into `~/.agents/skills/system-personalization/references/gotchas/` when deploying that profile.
> On fresh machines without that profile, the gotchas directory remains completely clean with only universal guardrails.

---

## 🔍 When to Document a Gotcha (Triggers)

Document an issue as a gotcha if it meets any of the following criteria:

- **Silent / Misleading Failure**: An error occurs but standard diagnostics (e.g. `journalctl`) return no logs (e.g. Hyprland Lua config errors).
- **Distribution Boundary / Safety**: An action seems reasonable but will cause data loss upon package upgrade (e.g. editing `/usr/share/omarchy/`).
- **Hardware / Firmware Quirk**: A physical button, sensor, latch, or power state requires a specific user-space daemon or kernel driver (e.g. `surface-dtx-daemon`, `iptsd`).
- **Headless / Agent Environment Quirk**: An AI agent running without a TTY fails on an interactive command (e.g. sudo password prompts requiring `pkexec` or floating presentation).
- **Input Method / Protocol Incompatibility**: A Wayland compositor quirk requiring specific environment variables or protocols (e.g. Fcitx5 text input).

### What NOT to Document as a Gotcha
- Temporary network glitches or package mirror timeouts.
- Simple typos resolved during initial config authoring.
- Standard Arch Linux / Hyprland documentation readily available in official man pages or wikis.

---

## 📝 Required Document Structure

Every gotcha document MUST follow this schema (available as a template in [`templates/gotcha-entry.md`](../../templates/gotcha-entry.md)):

```markdown
# [Clear, Actionable Title]

- **ID**: `[XX-kebab-slug]`
- **Category**: `[Hyprland | Hardware | Display | System | Security | Input | Wayland]`
- **Hardware / Target**: `[Universal | Microsoft Surface | Device Model]`
- **Severity**: `[Critical | Warning | Info]`

---

## Symptom
[Exact description of what fails, including error messages, terminal output, or visible UI behavior.]

## Root Cause
[Technical explanation of why the failure occurs: compositor internals, kernel driver communication, protocol mismatches, or systemd sandboxing.]

## Solution & Fix
[Step-by-step instructions, command lines, or exact Lua/bash configuration snippets needed to resolve the issue.]

\`\`\`bash
# Executable verification or repair commands
\`\`\`

## Verification
[Specific command or observable test to confirm that the fix resolved the problem.]

## Related References
- [`references/config-paths.md`](../config-paths.md)
- [Optional upstream link or skill reference]
```

---

## 🛠️ Step-by-Step Authoring Workflow

When resolving a quirk on a fresh machine:

### 1. Reproduce & Isolate
Identify the exact error message, symptom, and root cause before writing.

### 2. Choose the Target Location
- Universal: `agents/.agents/skills/system-personalization/references/gotchas/`
- Profile: `profiles/<profile>/gotchas/`

### 3. Determine the Filename & ID
Use the next sequential number followed by a short descriptive kebab-case slug:
`04-touchpad-multitouch-conflict.md`

### 4. Create from Template
Copy the structure from `agents/.agents/skills/system-personalization/templates/gotcha-entry.md` and complete all sections.

### 5. Index the Gotcha
- For **Universal Gotchas**: Add an entry to [`references/gotchas/INDEX.md`](INDEX.md).
- For **Profile Gotchas**: If the profile has an index, document it there, and ensure `profiles/<profile>/.stow-local-ignore` ignores `^gotchas` so Stow does not stow it directly to `$HOME`.

### 6. Record in Changelog
Add an entry in [`references/changelog.md`](../changelog.md) using the format in [`templates/change-entry.md`](../../templates/change-entry.md).

### 7. Verify Links & Markdown
Ensure all relative markdown links resolve correctly and verify git status.
