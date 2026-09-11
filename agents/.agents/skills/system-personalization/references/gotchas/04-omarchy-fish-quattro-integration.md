# Omarchy Quattro Fish Shell Integration & Autosuggestions

- **ID**: `04-omarchy-fish-quattro-integration`
- **Category**: `System`
- **Hardware / Target**: `Universal (Omarchy Quattro)`
- **Severity**: `Warning`

---

## Symptom
Running `/usr/bin/omarchy-setup-fish` from the `omarchy-fish` package overwrites `~/.bashrc` with an obsolete Omarchy 2/3 template pointing to `~/.local/share/omarchy/default/bash/rc`, completely breaking Omarchy Quattro's `/usr/share/omarchy/default/bash/env-bootstrap` and wiping custom user `PATH` exports. Additionally, `omarchy-fish` defaults to `fish_vi_key_bindings`, disrupting standard desktop navigation and macOS-style editing bindings.

## Root Cause
Upstream `omarchy-fish` includes a legacy helper script (`omarchy-setup-fish`) designed before Omarchy 4.0 (Quattro). Quattro relocated Omarchy's system defaults to `/usr/share/omarchy/` and requires environment bootstrapping even for non-interactive shells. Furthermore, Fish's vendor config in `/usr/share/fish/vendor_conf.d/init.fish` forces vi mode bindings by default.

## Solution & Fix

1. **Do NOT run `omarchy-setup-fish` directly.**
2. **Configure Foot terminal directly**:
   In `core/.config/foot/foot.ini`:
   ```ini
   [main]
   shell=/usr/bin/fish
   ```
3. **Add a clean, non-destructive auto-launch guard to `~/.bashrc`**:
   ```bash
   # Auto-launch fish shell for interactive sessions (CachyOS terminal experience)
   if command -v fish &>/dev/null; then
     if [[ $(ps --no-header --pid=$PPID --format=comm) != "fish" && -z ${BASH_EXECUTION_STRING} ]]; then
       shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=''
       exec fish $LOGIN_OPTION
     fi
   fi
   ```
4. **Override vi mode in `core/.config/fish/config.fish`**:
   ```fish
   if status is-interactive
       fish_default_key_bindings
       set -g fish_color_autosuggestion 555 brblack
       fish_add_path -m $HOME/.local/bin
   end
   ```

## Verification
1. Launch terminal with `SUPER + Return` or run `foot`.
2. Verify Starship prompt loads and Fish shell is running (`echo $status`).
3. Type a command (e.g. `git stat`) — verify gray ghost suggestions appear and `Right Arrow` or `Ctrl+F` autocompletes the line.
4. Verify non-interactive scripts (`bash -c "..."`) continue executing in standard Bash without entering Fish.

## Related References
- [`references/config-paths.md`](../config-paths.md)
- [`references/keybindings.md`](../keybindings.md)
