# Bluetooth delay tuner corrections

Product ID: `orange-pi-android-tv`

Transaction parent: `5615b048d079e9a21348c121e52811c7224b5174`

## Goal

Correct the tuner UI in TvSettings and make Hybrid A2DP tuning affect effective
reported latency. This repository owns the HAL semantics and native tests; the
TvSettings repository owns the activity, endpoint visuals, summaries, and UI
tests.

## Required behavior

- Hybrid + Relative + valid report: report plus configured offset.
- Hybrid + Relative + no valid report: fallback plus configured offset.
- Hybrid + Absolute + valid report: valid report unchanged.
- Hybrid + Absolute + no valid report: configured absolute value.
- Preserve property names, parsing bounds, report validity, route gating, and
  effective latency clamping.
- Verify focused tests/builds, the vendor audio APEX and affected images with
  `-j26`, then prove live effective latency changes on one uninterrupted A2DP
  stream before final image acceptance.

## Constraints

Do not use live deployment for the HAL/APEX change. Package and validate the
real system/vendor artifacts. Do not flash automatically; provide the exact
guarded `pkexec` NVMe flash command and wait for the user to flash and reboot.
Do not commit build output, logs, images, APKs, screenshots, or diagnostics.

## Slice index

1. TvSettings repository: isolate/mark the tuner and clarify summaries.
2. [Apply Hybrid effective-latency semantics](20260828212326_bluetooth_delay_tuner_corrections_slice_02.md)
