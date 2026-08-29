# Slice 03: Remove Orange Pi suspend blocker

## Goal and observable outcome

The Orange Pi product no longer packages or starts `suspend_blocker_opi`, so
Android auto-suspend may enter kernel deep suspend after the display becomes
noninteractive.

## Scope

- Remove the blocker APEX/product package integration.
- Delete its obsolete executable/build definitions, init service, APEX files,
  file contexts, and dedicated SELinux policy/allow rules.
- Retain `config_useAutoSuspend=true` and all unrelated product contents.

Non-scope: replacement daemons, timing workarounds, PowerManager behavior,
kernel implementation, USB gadget mode, and unrelated SELinux cleanup.

## Dependencies and ordering

This product slice can build independently but must be combined with slices 01
and 02 for functional acceptance. Final `vendor.img` must package modules from
the exact rebuilt kernel paired with `boot.img`.

## Entry point and state transition

At boot, no init/APEX service acquires the permanent partial wake lock. With
the display noninteractive, the existing Android SystemSuspend path and
`config_useAutoSuspend=true` can transition to kernel suspend. There is no new
service or persisted state.

## Authorization, validation, and errors

No new permissions or SELinux authority are introduced. All policy and file
labels that existed solely for the deleted blocker are removed. A repository
search must find no live product reference; unrelated historical delivery plans
may retain descriptive text.

## Implementation surfaces

- product makefiles containing `suspend_blocker_opi`
- `suspend_blocker/` implementation/APEX/init files
- `sepolicy/suspend_blocker.te`, related file contexts, and policy references
- overlay/config only for verifying, not changing, auto-suspend

## Tests and validation

Positive: product/Soong configuration succeeds and `vendor.img` builds with
`-j26`; extracted vendor contents have no blocker APEX, binary, init RC, or
policy artifact; overlay inspection proves `config_useAutoSuspend=true`.

Negative: repository search finds no active integration; no replacement wake
lock, service, sleep, polling, or fixed delay appears; unrelated product/GMS,
ADB, USB host, and module packaging remains unchanged.

## Acceptance criteria

The blocker is fully absent from product sources and built vendor image,
auto-suspend remains enabled, required Android image builds pass, and only
source/plan files are committed.

## Commit boundary

One Orange Pi device repository commit containing this plan and blocker
integration/implementation/policy removal. Exclude images, logs, and outputs.

## Execution record

- Built `bootimage`, `systemimage`, and `vendorimage` with `-j26` after staging
  the same-build kernel and target DTB; the integrated build completed
  successfully and all APEX SELinux checks passed.
- Build cleanup explicitly removed the blocker binary, init file, libraries,
  staging directory, and `com.android.hardware.suspend_blocker.opi5.apex`.
- Inspected the final `vendor.img`: it contains no blocker APEX or blocker
  artifact and retains the Widevine hardware APEX.
- Verified the framework default remains `config_useAutoSuspend=true`, with no
  replacement service, polling loop, fixed delay, or wake-lock integration.
