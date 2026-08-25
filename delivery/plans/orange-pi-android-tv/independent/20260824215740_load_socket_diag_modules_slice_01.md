# Slice 01: Load TCP diagnostic modules after mounting vendor

## Goal and observable outcome

Every normal boot loads `inet_diag` and then `tcp_diag`. Netd's
`TcpSocketMonitor` can enumerate active IPv4 and IPv6 TCP sockets and no longer
logs `Failed to dump IPv4 sockets struct tcp_info: No such file or directory`.

## Scope and non-scope

The slice changes only the Orange Pi init configuration and its delivery plan.
It does not change module binaries, kernel configuration, network accounting,
netd log verbosity, userdata, or any network route or policy.

## Dependencies and ordering

- `/vendor` must be mounted before either module path is accessed.
- `inet_diag.ko` must load before its dependent `tcp_diag.ko`.
- The rebuilt `vendor.img` must retain the already-matched module binaries.
  This slice does not alter the kernel, module binaries, or their CRCs.

## Entry point and behavior

Android init reaches `post-fs` after `mount_all ... --early` has mounted the
vendor filesystem. It executes two built-in `insmod` commands in dependency
order. A missing or incompatible module produces an init/kernel error rather
than being silently ignored. On success, netd's existing polling thread uses
the registered INET diagnostic handlers without further configuration.

## Data, state, and authorization

The only state transition is kernel module registration for the duration of
the boot. Android init already runs with the authority required to load kernel
modules. No persistent application data, credentials, permissions, or user
authorization are involved.

## Implementation surfaces

- `ramdisk/init.opi5.rc`
- This governing plan and slice plan

## Validation and recovery

Positive validation:

1. Parse the init file with the host init verifier or the vendor-image build.
2. Build `vendorimage` with no more than six parallel jobs.
3. Inspect the generated vendor image and confirm both `insmod` lines occur
   once, after the vendor early-mount action and in dependency order.
4. Runtime acceptance after flashing: both modules appear in `/proc/modules`;
   `dumpsys netd tcp_socket_info` reports live sockets; no new ENOENT errors
   appear after boot.

Negative validation:

1. Confirm the init action does not load `tcp_diag` before `inet_diag`.
2. Confirm no kernel, vendor module, userdata, netd source, timing, or log-level
   setting changed.
3. Confirm `boot.img`, the kernel, and the packaged module binaries remain
   unchanged during the build.

Recovery is flashing the preceding known-good `vendor.img`; userdata and boot
do not need restoration.

## Acceptance criteria

- The init rule is syntactically valid and loads exactly the two required
  modules in the correct phase and order.
- A verified replacement `vendor.img` is produced using `-j6` or fewer jobs.
- `boot.img` and the packaged module binaries are unchanged.
- The slice and its plan are committed together as one reviewable commit.

## Commit boundary

Commit the two plan files and `ramdisk/init.opi5.rc` together after source,
build, and vendor-image-content validation succeeds.

## Validation evidence

- `host_init_verifier` accepted `ramdisk/init.opi5.rc`.
- `m -j6 vendorimage` completed successfully for
  `aosp_opi5_pro_tv-cp2a-userdebug`.
- Generated vendor image SHA-256:
  `fd08913d54fbc10ed8b7a73452401acb909c2f8a62797f904fd90e62f373048a`.
- `e2fsck -fn` completed all five passes without errors.
- Reading `/etc/init/hw/init.opi5.rc` directly from the generated image
  confirmed each command occurs once and `inet_diag` precedes `tcp_diag`.
- `boot.img` remained
  `2b538e04ca2ba546d9a4af38469f7098302e01b353e1a41eb366454bceab2885`.
- The packaged `inet_diag.ko` and `tcp_diag.ko` hashes remained respectively
  `eae588331fc7664ea07eff78ad3f00b7e37e91bd70b43703f6d59137f13b35e1`
  and
  `971aff2729aba4a79ddc97e46278bdbcc3368a87570217bbcbe61e80cb390f44`.
- Live pre-build validation loaded those exact packaged modules and made
  `dumpsys netd tcp_socket_info` return active socket statistics without an
  immediate diagnostic failure.
