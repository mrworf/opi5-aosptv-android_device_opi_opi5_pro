#!/usr/bin/env python3
"""Verify Orange Pi Bluetooth suspend policy in source and packaged outputs."""

from __future__ import annotations

import argparse
from pathlib import Path
import subprocess
import sys


REQUIRED_PROPERTIES = {
    "bluetooth.power.suspend.disconnect_acl.enabled": "true",
    "bluetooth.power.suspend.scan_mode_none.enabled": "true",
    "bluetooth.power.suspend.stop_le_scan.enabled": "true",
    "bluetooth.power.suspend.pause_advertisement.enabled": "true",
}
REQUIRED_FLAGS = {
    "adapter_suspend_mgmt": "ENABLED:READ_ONLY",
    "le_hid_connection_policy_suspend": "ENABLED:READ_ONLY",
}


def parse_properties(text: str) -> dict[str, str]:
    properties: dict[str, str] = {}
    for raw_line in text.splitlines():
        line = raw_line.strip().rstrip("\\").strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        properties[key.strip()] = value.strip()
    return properties


def verify_source(device_root: Path, release_root: Path) -> list[str]:
    errors: list[str] = []
    product_mk = (device_root / "aosp_opi5_pro_tv.mk").read_text(encoding="utf-8")
    if "build/release/opi5_pro/release_config_map.textproto" not in product_mk:
        errors.append("TV product does not include its release-config map")

    properties = parse_properties(product_mk)
    for key, expected in REQUIRED_PROPERTIES.items():
        if properties.get(key) != expected:
            errors.append(f"{key}: expected {expected}, got {properties.get(key, 'missing')}")

    flag_value = release_root / (
        "aconfig/cp2a/com.android.bluetooth.flags/"
        "adapter_suspend_mgmt_flag_values.textproto"
    )
    if not flag_value.is_file():
        errors.append("adapter_suspend_mgmt CP2A override is missing")
    else:
        value = flag_value.read_text(encoding="utf-8")
        for token in (
            'package: "com.android.bluetooth.flags"',
            'name: "adapter_suspend_mgmt"',
            "state: ENABLED",
            "permission: READ_ONLY",
        ):
            if token not in value:
                errors.append(f"adapter_suspend_mgmt override lacks {token}")
    return errors


def verify_built_properties(path: Path) -> list[str]:
    properties = parse_properties(path.read_text(encoding="utf-8"))
    return [
        f"packaged {key}: expected {expected}, got {properties.get(key, 'missing')}"
        for key, expected in REQUIRED_PROPERTIES.items()
        if properties.get(key) != expected
    ]


def verify_aconfig(tool: Path, cache: Path) -> list[str]:
    result = subprocess.run(
        [
            str(tool),
            "dump-cache",
            "--cache",
            str(cache),
            "--filter=package:com.android.bluetooth.flags",
            "--format={name}={state}:{permission}",
        ],
        check=True,
        capture_output=True,
        text=True,
    )
    values = dict(line.split("=", 1) for line in result.stdout.splitlines() if "=" in line)
    return [
        f"built flag {name}: expected {expected}, got {values.get(name, 'missing')}"
        for name, expected in REQUIRED_FLAGS.items()
        if values.get(name) != expected
    ]


def verify_extracted_apex(path: Path) -> list[str]:
    errors: list[str] = []
    for name in ("aconfig_flags.pb", "flag.info", "flag.map", "flag.val"):
        candidate = path / "etc" / name
        if not candidate.is_file() or candidate.stat().st_size == 0:
            errors.append(f"packaged Bluetooth APEX lacks non-empty etc/{name}")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--device-root", type=Path, required=True)
    parser.add_argument("--release-root", type=Path, required=True)
    parser.add_argument("--vendor-build-prop", type=Path)
    parser.add_argument("--aconfig-tool", type=Path)
    parser.add_argument("--aconfig-cache", type=Path)
    parser.add_argument("--extracted-apex", type=Path)
    args = parser.parse_args()

    errors = verify_source(args.device_root, args.release_root)
    if args.vendor_build_prop:
        errors.extend(verify_built_properties(args.vendor_build_prop))
    if bool(args.aconfig_tool) != bool(args.aconfig_cache):
        errors.append("--aconfig-tool and --aconfig-cache must be supplied together")
    elif args.aconfig_tool:
        errors.extend(verify_aconfig(args.aconfig_tool, args.aconfig_cache))
    if args.extracted_apex:
        errors.extend(verify_extracted_apex(args.extracted_apex))

    if errors:
        print("Bluetooth suspend verification failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print("Bluetooth HID wake and suspend policy verified")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
