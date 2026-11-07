"""Exercise palette refresh against synthetic /proc entries, never personal sessions."""

import importlib.machinery
import importlib.util
import os
from pathlib import Path
import select
import signal
import subprocess
import sys
import tempfile
import unittest
from unittest import mock


ROOT = Path(__file__).resolve().parents[1]
HELPER = ROOT / "core/.local/bin/omarchy-opencode-theme-refresh"
HOOK = ROOT / "core/.config/omarchy/hooks/theme-set.d/20-opencode-system-refresh"
loader = importlib.machinery.SourceFileLoader("opencode_theme_refresh", str(HELPER))
spec = importlib.util.spec_from_loader(loader.name, loader)
refresh = importlib.util.module_from_spec(spec)
loader.exec_module(refresh)


class RefreshTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="opencode-refresh-test-", dir="/tmp/opencode")
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.proc = self.root / "proc"
        self.proc.mkdir()

    def process(self, pid=123, name="opencode.exe", handler=True, tty="/dev/pts/99", executable=None, args=()):
        process = self.proc / str(pid)
        (process / "fd").mkdir(parents=True)
        (process / "comm").write_text(name + "\n")
        (process / "exe").symlink_to(executable or "/fake/bin/" + name)
        (process / "fd/0").symlink_to(tty)
        (process / "fd/1").symlink_to(tty)
        caught = (1 << (signal.SIGUSR2 - 1)) if handler else 0
        (process / "status").write_text(f"Name:\t{name}\nSigCgt:\t{caught:016x}\n")
        (process / "cmdline").write_bytes(b"\0".join(value.encode() for value in [name, *args]) + b"\0")
        return process

    def test_both_native_and_npm_tui_names_are_eligible(self):
        for pid, name in enumerate(("opencode", "opencode.exe"), start=100):
            self.assertTrue(refresh.is_tui(self.process(pid=pid, name=name), os.geteuid()))
        with mock.patch.object(refresh.os, "pidfd_open") as opened, mock.patch.object(refresh.signal, "pidfd_send_signal") as send:
            self.assertEqual(refresh.refresh(self.proc, dry_run=True), [100, 101])
            opened.assert_not_called()
            send.assert_not_called()

    def test_headless_service_and_non_tty_processes_are_skipped(self):
        for pid, args, tty in [(100, ("serve", "--service"), "/dev/null"), (101, ("serve",), "/dev/pts/99"),
                               (102, ("service", "status"), "/dev/pts/99"), (103, (), "/dev/null")]:
            self.assertFalse(refresh.is_tui(self.process(pid=pid, args=args, tty=tty), os.geteuid()))

    def test_signal_handler_is_mandatory(self):
        self.assertFalse(refresh.is_tui(self.process(handler=False), os.geteuid()))
        self.assertEqual(refresh.refresh(self.proc, dry_run=True), [])

    def test_process_name_alone_is_not_sufficient(self):
        self.assertFalse(refresh.is_tui(self.process(executable="/usr/bin/python3"), os.geteuid()))
        self.assertFalse(refresh.is_tui(self.process(pid=124, name="not-opencode"), os.geteuid()))

    def test_other_users_and_mismatched_terminals_are_skipped(self):
        process = self.process()
        self.assertFalse(refresh.is_tui(process, os.geteuid() + 1))
        (process / "fd/1").unlink()
        (process / "fd/1").symlink_to("/dev/pts/98")
        self.assertFalse(refresh.is_tui(process, os.geteuid()))

    def test_incomplete_process_metadata_is_skipped(self):
        process = self.process()
        (process / "status").write_text("SigCgt: not-hex\n")
        self.assertFalse(refresh.is_tui(process, os.geteuid()))
        (process / "status").unlink()
        self.assertFalse(refresh.is_tui(process, os.geteuid()))

    def test_pidfd_signal_is_used_and_descriptor_is_closed(self):
        self.process()
        self.process(pid=124, args=("serve", "--service"))
        with mock.patch.object(refresh.os, "pidfd_open", return_value=77) as opened, \
             mock.patch.object(refresh.os, "close") as close, \
             mock.patch.object(refresh.signal, "pidfd_send_signal") as send:
            self.assertEqual(refresh.refresh(self.proc), [123])
            opened.assert_called_once_with(123)
            send.assert_called_once_with(77, signal.SIGUSR2)
            close.assert_called_once_with(77)

    def test_process_is_rechecked_after_opening_pidfd(self):
        process = self.process()
        def replace_process(pid):
            (process / "comm").write_text("other-program\n")
            return 77
        with mock.patch.object(refresh.os, "pidfd_open", side_effect=replace_process), \
             mock.patch.object(refresh.os, "close") as close, \
             mock.patch.object(refresh.signal, "pidfd_send_signal") as send:
            self.assertEqual(refresh.refresh(self.proc), [])
            send.assert_not_called()
            close.assert_called_once_with(77)

    def test_closing_windows_do_not_fail_the_refresh(self):
        self.process()
        with mock.patch.object(refresh.os, "pidfd_open", side_effect=ProcessLookupError):
            self.assertEqual(refresh.refresh(self.proc), [])
        with mock.patch.object(refresh.os, "pidfd_open", return_value=77), \
             mock.patch.object(refresh.os, "close") as close, \
             mock.patch.object(refresh.signal, "pidfd_send_signal", side_effect=ProcessLookupError):
            self.assertEqual(refresh.refresh(self.proc), [])
            close.assert_called_once_with(77)

    def test_real_signal_reaches_only_a_disposable_test_process(self):
        script = "import signal; signal.signal(signal.SIGUSR2, lambda *_: print('REFRESHED', flush=True)); print('READY', flush=True);\nwhile True: signal.pause()"
        child = subprocess.Popen([sys.executable, "-u", "-c", script], stdout=subprocess.PIPE, text=True)
        try:
            self.assertTrue(select.select([child.stdout], [], [], 5)[0], "Test process did not become ready")
            self.assertEqual(child.stdout.readline().strip(), "READY")
            self.process(pid=child.pid)
            self.assertEqual(refresh.refresh(self.proc), [child.pid])
            self.assertTrue(select.select([child.stdout], [], [], 5)[0], "Test process did not receive its signal")
            self.assertEqual(child.stdout.readline().strip(), "REFRESHED")
            self.assertIsNone(child.poll())
        finally:
            child.terminate()
            child.wait(timeout=5)
            child.stdout.close()

    def test_native_hook_calls_the_user_helper(self):
        binary = self.root / ".local/bin/omarchy-opencode-theme-refresh"
        binary.parent.mkdir(parents=True)
        binary.write_text("#!/bin/sh\necho refreshed\n")
        binary.chmod(0o755)
        result = subprocess.run(["bash", str(HOOK), "aether"], env=dict(os.environ, HOME=str(self.root)), text=True, capture_output=True, timeout=5)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), "refreshed")


if __name__ == "__main__":
    unittest.main()
