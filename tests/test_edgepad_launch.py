import importlib.machinery
import importlib.util
import subprocess
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
LAUNCHER_PATH = REPO_ROOT / "core/.local/bin/edgepad-launch"


def load_launcher_module():
    loader = importlib.machinery.SourceFileLoader("edgepad_launch", str(LAUNCHER_PATH))
    spec = importlib.util.spec_from_loader(loader.name, loader)
    assert spec is not None
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


edgepad_launch = load_launcher_module()


class TestEdgepadLaunch(unittest.TestCase):
    def test_compute_edge_width_fraction_across_touchpad_sizes(self):
        # Dell XPS 13 (117.32 mm) -> ~4.26% = 5.00 mm
        self.assertEqual(edgepad_launch.compute_edge_width_fraction(5.0, 117.3226), 0.0426)
        # Typical 105 mm laptop touchpad -> ~4.76% = 5.00 mm
        self.assertEqual(edgepad_launch.compute_edge_width_fraction(5.0, 105.0), 0.0476)
        # Compact 85 mm touchpad -> ~5.88% = 5.00 mm
        self.assertEqual(edgepad_launch.compute_edge_width_fraction(5.0, 85.0), 0.0588)

    def test_compute_edge_width_fraction_clamps_extremes(self):
        self.assertEqual(edgepad_launch.compute_edge_width_fraction(5.0, 400.0), 0.02)
        self.assertEqual(edgepad_launch.compute_edge_width_fraction(5.0, 25.0), 0.15)

    def test_parse_target_edge_mm(self):
        self.assertEqual(edgepad_launch.parse_target_edge_mm(None, None), 5.0)
        self.assertEqual(edgepad_launch.parse_target_edge_mm(4.5, "6.0"), 4.5)
        self.assertEqual(edgepad_launch.parse_target_edge_mm(None, "4.0"), 4.0)
        self.assertIsNone(edgepad_launch.parse_target_edge_mm(None, "off"))
        self.assertIsNone(edgepad_launch.parse_target_edge_mm(0.0, "5.0"))

    def test_parse_edgepad_devices_output(self):
        sample = (
            '/dev/input/event4 kind=other name="Keyboard"\n'
            '/dev/input/event9 kind=touchpad name="GXTP7863:00 27C6:0D4C Touchpad" '
            "id=27c6:0d4c slots=0..=4 x=0..=3637 y=0..=2063\n"
        )
        self.assertEqual(
            edgepad_launch.parse_edgepad_devices_output(sample),
            ["/dev/input/event9"],
        )

    def test_discover_touchpad_device_handles_ambiguity_and_explicit(self):
        self.assertEqual(
            edgepad_launch.discover_touchpad_device("/bin/edgepad", "/dev/input/event7"),
            "/dev/input/event7",
        )

        def multi_runner(*_args, **_kwargs):
            return subprocess.CompletedProcess(
                args=[],
                returncode=0,
                stdout=(
                    "/dev/input/event7 kind=touchpad name=\"Pad 1\"\n"
                    "/dev/input/event9 kind=touchpad name=\"Pad 2\"\n"
                ),
                stderr="",
            )

        self.assertIsNone(
            edgepad_launch.discover_touchpad_device(
                "/bin/edgepad",
                "auto",
                attempts=1,
                runner=multi_runner,
                sleeper=lambda _s: None,
            )
        )

    def test_read_udev_width_mm_fallback(self):
        def fake_udev(*_args, **_kwargs):
            return subprocess.CompletedProcess(
                args=[],
                returncode=0,
                stdout="DEVNAME=/dev/input/event9\nID_INPUT_WIDTH_MM=117\n",
                stderr="",
            )

        width = edgepad_launch.detect_touchpad_width_mm(
            "/dev/input/event9",
            evdev_reader=lambda _p: None,
            udev_reader=lambda p: edgepad_launch.read_udev_width_mm(p, runner=fake_udev),
        )
        self.assertEqual(width, 117.0)

    def test_build_daemon_command_with_autoscaling_and_fallback(self):
        with tempfile.TemporaryDirectory() as tmp:
            cfg = Path(tmp) / "edgepad.toml"
            cfg.write_text('device = "auto"\nedge_width = 0.045\n', encoding="utf-8")

            argv, summary = edgepad_launch.build_daemon_command(
                edgepad_bin="/usr/local/bin/edgepad",
                config_path=cfg,
                device_override=None,
                input_root=None,
                edge_width_override=None,
                target_edge_mm=5.0,
                device_discoverer=lambda *_a: "/dev/input/event9",
                width_detector=lambda _p: 117.3226,
            )
            self.assertEqual(
                argv,
                [
                    "/usr/local/bin/edgepad",
                    "daemon",
                    "--config",
                    str(cfg),
                    "--edge-width",
                    "0.0426",
                ],
            )
            self.assertIn("5.00mm", summary)

            fallback_argv, fallback_summary = edgepad_launch.build_daemon_command(
                edgepad_bin="/usr/local/bin/edgepad",
                config_path=cfg,
                device_override=None,
                input_root=None,
                edge_width_override=None,
                target_edge_mm=5.0,
                device_discoverer=lambda *_a: None,
                width_detector=lambda _p: None,
            )
            self.assertEqual(
                fallback_argv,
                ["/usr/local/bin/edgepad", "daemon", "--config", str(cfg)],
            )
            self.assertIn("falling back", fallback_summary)


if __name__ == "__main__":
    unittest.main()
