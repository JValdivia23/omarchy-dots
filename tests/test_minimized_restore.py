"""Exercise the restore helper without dispatching to a real compositor."""

import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


HELPER = Path(__file__).resolve().parents[1] / "core/.local/bin/hypr-restore-window"
PLUGIN = HELPER.parents[2] / ".config/omarchy/plugins/jairo.minimized-windows"
SHELL = Path(os.environ.get("OMARCHY_PATH", "/usr/share/omarchy")) / "shell"
ADDRESS = "0x1234"

MOCK = r'''#!/usr/bin/env python3
import json, os, pathlib, sys
state_file = pathlib.Path(os.environ["RESTORE_TEST_STATE"])
state = json.loads(state_file.read_text())
args = sys.argv[1:]
if args[0] == "clients":
    print(json.dumps([] if state.get("missing") else [{"address": "0x1234", "workspace": state["workspace"]}]))
elif args[0] == "monitors":
    print(json.dumps([{"focused": True, "specialWorkspace": {"name": state.get("special", "")}}]))
elif args[0] == "dispatch":
    action = args[1]
    state["actions"].append(action)
    if "window.move" in action:
        if state.get("reject"):
            state_file.write_text(json.dumps(state))
            print("error: move rejected")
            sys.exit(0)
        if not state.get("no_move"):
            state["workspace"] = {"id": 3, "name": "3"}
    if "toggle_special" in action:
        state["special"] = ""
    state_file.write_text(json.dumps(state))
    print("ok")
else:
    sys.exit(2)
'''


class RestoreTests(unittest.TestCase):
    def run_restore(self, changes=None, address=ADDRESS, workspace="3"):
        state = {"workspace": {"id": -98, "name": "special:minimized"}, "actions": []}
        state.update(changes or {})
        with tempfile.TemporaryDirectory(prefix="restore-test-", dir="/tmp/opencode") as directory:
            directory = Path(directory)
            state_file = directory / "state.json"
            state_file.write_text(json.dumps(state))
            mock = directory / "hyprctl"
            mock.write_text(MOCK)
            mock.chmod(0o755)
            env = dict(os.environ, PATH=str(directory) + os.pathsep + os.environ["PATH"], RESTORE_TEST_STATE=str(state_file))
            result = subprocess.run(["bash", str(HELPER), address, workspace], env=env, capture_output=True, text=True, timeout=5)
            return result, json.loads(state_file.read_text())

    def test_restore_moves_before_focus_like_dock(self):
        result, state = self.run_restore()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(state["workspace"]["id"], 3)
        actions = state["actions"]
        self.assertIn('window.move({ workspace = "3", window = "address:0x1234" })', actions[1])
        self.assertIn("dsp.focus", actions[2])
        self.assertIn('value = "unset"', actions[-1])
        self.assertFalse(any("toggle_special" in action for action in actions))

    def test_success_reply_without_move_never_focuses_special(self):
        result, state = self.run_restore({"no_move": True})
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("did not reach", result.stderr)
        self.assertFalse(any("dsp.focus" in action for action in state["actions"]))
        self.assertIn('value = "unset"', state["actions"][-1])

    def test_error_reply_with_zero_exit_is_rejected(self):
        result, state = self.run_restore({"reject": True})
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("move rejected", result.stderr)
        self.assertFalse(any("dsp.focus" in action for action in state["actions"]))

    def test_only_visible_minimized_overlay_is_closed(self):
        result, state = self.run_restore({"special": "special:minimized"})
        self.assertEqual(result.returncode, 0, result.stderr)
        toggle = next(i for i, action in enumerate(state["actions"]) if "toggle_special" in action)
        focus = next(i for i, action in enumerate(state["actions"]) if "dsp.focus" in action)
        self.assertLess(toggle, focus)
        result, state = self.run_restore({"special": "special:scratchpad"})
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(any("toggle_special" in action for action in state["actions"]))

    def test_stale_row_does_not_move_window_from_another_workspace(self):
        result, state = self.run_restore({"workspace": {"id": 4, "name": "4"}})
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(state["actions"], [])

    def test_already_restored_window_can_be_focused(self):
        result, state = self.run_restore({"workspace": {"id": 3, "name": "3"}})
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(any("window.move" in action for action in state["actions"]))

    def test_missing_window_is_reported(self):
        result, state = self.run_restore({"missing": True})
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("no longer available", result.stderr)
        self.assertEqual(state["actions"], [])

    def test_invalid_and_injected_arguments_are_rejected(self):
        for address, workspace in [("0x1234;touch /tmp/no", "3"), (ADDRESS, "special:minimized"), (ADDRESS, "0"), (ADDRESS, "2147483648")]:
            with self.subTest(address=address, workspace=workspace):
                result, state = self.run_restore(address=address, workspace=workspace)
                self.assertNotEqual(result.returncode, 0)
                self.assertEqual(state["actions"], [])


@unittest.skipUnless(shutil.which("qs") and (SHELL / "Ui").is_dir(), "Requires the Omarchy shell and Quickshell")
class InteractionTests(unittest.TestCase):
    def exercise_qml(self, fail, language):
        with tempfile.TemporaryDirectory(prefix="restore-qml-", dir="/tmp/opencode") as directory:
            root = Path(directory)
            for module in ("Commons", "Ui"):
                (root / module).symlink_to(SHELL / module)
            (root / "i18n").symlink_to(PLUGIN / "i18n")
            (root / "shell.qml").write_text((Path(__file__).parent / "minimized-windows/interaction.qml").read_text())
            source = (PLUGIN / "BarWidget.qml").read_text()
            start = source.index("  readonly property var minimizedWindows: {")
            end = source.index("  function close()", start)
            # Mock only compositor data; use the actual controller and visual QML.
            fixture = '''  readonly property var minimizedWindows: [
    { address: "1234", title: "<img src=https://example.invalid/test>", appId: "foot", appName: "Terminal", icon: "utilities-terminal" },
    { address: "5678", title: "Other window", appId: "foot", appName: "Terminal", icon: "utilities-terminal" }
  ]

'''
            source = source[:start] + fixture + source[end:]
            source = source.replace("var monitor = Hyprland.focusedMonitor", "var monitor = { activeWorkspace: { id: 3 } }")
            (root / "Fixture.qml").write_text(source)
            home = root / "home"
            language_file = home / ".config/omarchy/language"
            language_file.parent.mkdir(parents=True)
            language_file.write_text(language + "\n")
            binary = home / ".local/bin/hypr-restore-window"
            binary.parent.mkdir(parents=True)
            binary.write_text('''#!/bin/bash
printf '%s\\n' "$@" > "$HOME/arguments"
if [[ $RESTORE_TEST_FAIL == 1 ]]; then
  echo 'Forced move failure <img src=https://example.invalid/test>' >&2
  exit 1
fi
''')
            env = dict(os.environ, HOME=str(home), XDG_CONFIG_HOME=str(home / ".config"), QT_QPA_PLATFORM="offscreen", QT_QUICK_BACKEND="software", QT_FORCE_STDERR_LOGGING="1", RESTORE_TEST_FAIL=str(int(fail)))
            result = subprocess.run(["qs", "-p", str(root), "--no-color"], env=env, capture_output=True, text=True, timeout=15)
            output = result.stdout + result.stderr
            self.assertEqual(result.returncode, 0, output)
            self.assertNotIn("FAIL:", output, output)
            self.assertIn("PASS: Second icon click only closes the list", output, output)
            self.assertIn("PASS: Markup-shaped titles are plain text", output, output)
            self.assertIn("PASS: Failed restore displays" if fail else "PASS: Row restores only", output, output)
            self.assertEqual((home / "arguments").read_text().splitlines()[0], ADDRESS)

    def test_real_qml_success_path(self):
        for language in ("en", "ar"):
            with self.subTest(language=language):
                self.exercise_qml(fail=False, language=language)

    def test_real_qml_error_path(self):
        for language in ("en", "ar"):
            with self.subTest(language=language):
                self.exercise_qml(fail=True, language=language)


if __name__ == "__main__":
    unittest.main()
