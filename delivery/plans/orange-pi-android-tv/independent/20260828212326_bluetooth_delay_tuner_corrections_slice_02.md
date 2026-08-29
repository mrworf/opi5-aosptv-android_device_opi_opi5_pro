# Slice 02: Apply Hybrid effective-latency semantics

## Goal and observable outcome

Hybrid Relative adjustments affect live HAL-reported latency even when the
receiver supplies a valid A2DP Delay Report. Hybrid Absolute continues to trust
a valid report and uses its configured absolute value only as the missing-report
fallback.

## Scope and explicit non-scope

This slice owns the pure A2DP latency-selection logic and its native tests. It
does not change property names/defaults/ranges, report validity thresholds,
effective-latency bounds, stream lifecycle, codecs, transport, non-A2DP routes,
Bluetooth APIs, SELinux, kernel/modules, or TvSettings UI.

## Dependencies and ordering

- `calculateLatencyMs` remains the only policy helper called by the active AIDL
  A2DP output stream.
- `ManualSyncMode::AUTO` is the stored value backing the user-facing Hybrid
  choice; `ON` remains Manual and `OFF` remains Auto.
- UI wording is delivered separately in the TvSettings commit but both commits
  must be packaged for final acceptance.

## Entry point and end-to-end behavior

For eligible A2DP output latency queries, Off returns the existing latency.
Manual applies Relative to report/fallback or applies Absolute unconditionally.
Hybrid Relative applies the configured signed offset to a valid report or the
fallback. Hybrid Absolute returns a valid report unchanged or its configured
absolute fallback. Inputs and non-A2DP routes remain excluded upstream.

## Data, state, authorization, validation, and recovery

No data contract or authorization changes. The helper clamps configuration
values defensively and clamps its final result to 0..1250 ms. Malformed stored
properties keep existing safe defaults. Restoring original properties restores
the corresponding effective latency on the next query without reconnecting.

Positive tests cover all four Hybrid Relative/Absolute x valid/missing report
cases and in-range offsets. Negative/boundary tests cover low/high final
clamping, configured-value clamping, invalid report thresholds, Off
compatibility, and non-A2DP gating. Run `a2dp_manual_sync_test`, the vendor audio
service/APEX build, and affected system/vendor images with `-j26`.

Runtime validation must preserve and restore every original sync property and
use one uninterrupted D5 A2DP stream. Manual Absolute must show the same live
track-latency delta as two known configured values. Hybrid Relative 0 to +50 ms
with a valid D5 report must increase live track latency by 50 ms without a
reconnect/restart. Back must restore property and effective latency; Select must
preserve both. Capture AudioFlinger/audio-policy evidence of the active tuner
track routed to D5 and the effective-latency changes outside Git.

## Implementation surfaces

- `audio/bluetooth/A2dpManualSync.cpp`
- `audio/bluetooth/A2dpManualSyncTest.cpp`
- this governing plan and slice plan

## Acceptance criteria

- All Manual and Hybrid selection paths match the required truth table.
- Existing bounds, clamping, parsing, route gating, and live property observation
  remain intact.
- Focused native tests and required APEX/image builds pass.
- Image-level runtime evidence proves Hybrid Relative changes effective latency
  on a valid reporting sink without stream interruption.
- Only slice-owned files are committed in the Orange Pi device repository.

## Commit boundary

Commit the HAL semantics, tests, and these plan artifacts as one focused Orange
Pi device commit after required automated validation passes. Final runtime
acceptance follows packaged-image flashing by the user.

## Execution record

- All 13 arm64 `a2dp_manual_sync_test` cases passed on the connected Orange Pi,
  including all four Hybrid truth-table paths, valid-report offset behavior,
  missing-report fallback, report boundaries, malformed settings, route gating,
  and effective-latency clamping.
- `com.android.hardware.audio.opi5`, `systemimage`, and `vendorimage` built
  successfully with `-j26`. The final rebuild explicitly enabled and verified
  the repository's Widevine L3 bundle.
- The packaged system image contains the byte-identical corrected TvSettings
  APK (`e92d70f1c26d2d2afb0fa81225c719e705c40ccfbe93c5a5fc4dc870996b5cd8`).
  The packaged vendor image contains the byte-identical audio APEX
  (`a1a212f58ed57b4bfdbeddc788b6f9d238e8f34596d1daf73ceb26e06abbf75d`)
  and the verified Widevine L3 APEX.
- Final partition hashes after filesystem-label normalization are boot
  `23ded0197eb1160474f6d78469306ed5454e1c8818897b66b9a6ba5278752e87`,
  system `82e952154bb947322ec09f5fcdca9e29413d1f672fe4dd3bf782cb48cf80c86f`,
  and vendor `c755ffdde19ffafa1efde852d928e9d058d1a417bfc3e8d990142ae55ba68b11`.
- The rootless 19 GiB install image passed GPT verification, sidecar hash
  verification, and exact embedded boot/system/vendor comparisons. It selects
  the byte-identical `rk3588s-orangepi-5.dtb`, includes Google TV packages and
  the pre-authorized public ADB key, and has SHA-256
  `6a53527a295f4af4ff7f0fc54257968b47b70dc3f3896b45cf1e790070dcb850`.
- Physical flash and uninterrupted-stream effective-latency acceptance remain
  pending the required user-operated NVMe reflash.
