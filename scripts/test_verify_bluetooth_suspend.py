#!/usr/bin/env python3

from pathlib import Path
import sys
import tempfile
import unittest


sys.path.insert(0, str(Path(__file__).resolve().parent))
from verify_bluetooth_suspend import (  # noqa: E402
    REQUIRED_PROPERTIES,
    verify_built_properties,
    verify_extracted_apex,
)


class BluetoothSuspendVerifierTest(unittest.TestCase):
    def test_accepts_required_packaged_properties(self) -> None:
        with tempfile.TemporaryDirectory(dir=Path.cwd()) as directory:
            build_prop = Path(directory) / "build.prop"
            build_prop.write_text(
                "\n".join(f"{key}={value}" for key, value in REQUIRED_PROPERTIES.items()),
                encoding="utf-8",
            )
            self.assertEqual([], verify_built_properties(build_prop))

    def test_rejects_disabled_packaged_property(self) -> None:
        with tempfile.TemporaryDirectory(dir=Path.cwd()) as directory:
            build_prop = Path(directory) / "build.prop"
            build_prop.write_text(
                "bluetooth.power.suspend.disconnect_acl.enabled=false\n", encoding="utf-8"
            )
            self.assertTrue(verify_built_properties(build_prop))

    def test_rejects_incomplete_packaged_apex(self) -> None:
        with tempfile.TemporaryDirectory(dir=Path.cwd()) as directory:
            apex = Path(directory)
            (apex / "etc").mkdir()
            (apex / "etc" / "flag.val").write_bytes(b"value")
            self.assertTrue(verify_extracted_apex(apex))


if __name__ == "__main__":
    unittest.main()
