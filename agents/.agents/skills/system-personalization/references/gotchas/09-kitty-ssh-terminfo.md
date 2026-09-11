# Remote SSH Hosts Lack `xterm-kitty` Terminfo (ZSH Character Duplication)

- **ID**: `09-kitty-ssh-terminfo`
- **Category**: `Terminal / SSH`
- **Hardware / Target**: `Universal`
- **Severity**: `Warning`

---

## Symptom
When connecting to a remote Linux host or server via SSH (`ssh <remote-host>`) from Kitty, typing inside interactive shells (Bash, ZSH, Fish) or CLI tools results in duplicated or ghost characters (e.g. `cd repo` appears as `ccd repoorepo`), broken cursor movement with arrow keys, or raw escape codes printing to screen.

## Root Cause
Kitty sets the environment variable `TERM=xterm-kitty`. Most remote Linux distributions or barebone servers only include standard terminfo databases (`xterm`, `xterm-256color`, `vt100`) and lack the `xterm-kitty` terminfo entry. Without the matching terminfo file, the remote shell's line editor (e.g. ZSH ZLE or Readline) fails to calculate cursor repositioning codes (`cub1`, `cuf1`, `kbs`), causing redraw commands to print side-by-side rather than overwriting in place.

## Solution & Fix

### Option 1: Use Kitty's Built-in SSH Kitten (Recommended)
Use Kitty's built-in SSH kitten, which automatically transfers the terminfo database to the remote host upon connection:
```bash
kitty +kitten ssh <user>@<remote-host>
```
You can alias `ssh` to `kitty +kitten ssh` inside `~/.config/fish/config.fish` or `~/.bashrc`.

### Option 2: Copy Terminfo Database to Remote Host via `infocmp`
If using standard `ssh`, export and compile your local `xterm-kitty` terminfo onto the remote system once:
```bash
infocmp -a xterm-kitty | ssh <user>@<remote-host> "tic -x -"
```
This compiles the terminfo definitions into `~/.terminfo/` on the remote server.

### Option 3: Fallback TERM Environment Variable
For single-session ad-hoc logins where you cannot install terminfo on the host:
```bash
TERM=xterm-256color ssh <user>@<remote-host>
```

## Verification
SSH into the remote host and type rapid commands with arrow key cursor repositioning. Verify no ghost characters or line corruption occurs.

## Related References
- [`references/config-paths.md`](../config-paths.md)
- Kitty Terminal Documentation: `https://sw.kovidgoyal.net/kitty/overview/#term-info`
