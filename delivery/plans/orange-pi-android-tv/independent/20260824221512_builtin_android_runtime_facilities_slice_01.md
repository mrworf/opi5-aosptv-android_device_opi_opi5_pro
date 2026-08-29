# Slice 01: Provide built-in socket diagnostics and uinput

## Goal and observable outcome

The kernel exposes TCP and UDP INET socket diagnostics and `/dev/uinput`
without loading their former `.ko` files. Netd can poll TCP socket information
from early boot, and Android virtual-input consumers do not depend on module
autoloading.

## Scope and explicit non-scope

Change four Orange Pi kernel configuration values from modules to built-ins and
remove the now-redundant init `insmod` action. `CONFIG_BRIDGE` and all other
module selections remain unchanged. Userdata is not rebuilt, formatted, or
flashed.

## Dependencies and ordering

- `CONFIG_INET_TCP_DIAG=y` and `CONFIG_INET_UDP_DIAG=y` depend on
  `CONFIG_INET_DIAG=y`.
- `CONFIG_INET_DIAG_DESTROY=y` remains enabled.
- Because `CONFIG_MODVERSIONS=y`, the kernel and complete matching vendor module
  set must be rebuilt and delivered together.
- The Orange Pi 5 v1.2 image must retain `rk3588s-orangepi-5.dtb`.

## Entry point and end-to-end behavior

The kernel registers the diagnostic protocols and uinput driver during kernel
initialization. Android netd opens `NETLINK_INET_DIAG` directly; no hardware
modalias or init-time module load is required. Android input services can open
the kernel-created uinput device when needed.

## Data, state, authorization, and recovery

No persistent user data, credentials, or application authorization changes.
Kernel facilities remain subject to their existing device-node, capability,
and SELinux controls. Recovery is flashing the preceding matching boot and
vendor images; userdata does not require restoration.

## Implementation surfaces

- `android_kernel_rk_opi/arch/arm64/configs/android_orangepi5_defconfig`
- `aosp-workspace/device/opi/opi5_pro/BoardConfig.mk` (packaging comment only)
- `aosp-workspace/device/opi/opi5_pro/ramdisk/init.opi5.rc`
- This governing plan and slice plan

## Validation and error handling

Positive validation:

1. Regenerate `.config` and confirm all four selected symbols resolve to `y`.
2. Build `Image`, DTBs, and all modules with `-j26` and workspace-local
   temporary paths.
3. Confirm the resulting kernel reports all four facilities in
   `modules.builtin` or the generated `.config`, while bridge remains `m`.
4. Rebuild matching Android boot and vendor images with `-j26`.
5. Verify the generated boot image retains `rk3588s-orangepi-5.dtb` and the
   generated vendor image no longer contains the init `insmod` workaround.
6. Confirm the four former built-in `.ko` files are absent from the packaged
   module inventory while the complete remaining module set is retained.

Negative validation:

1. Confirm `CONFIG_BRIDGE=m`.
2. Confirm no private ADB key is introduced.
3. Confirm no userdata image is flashed or filesystem reformatted.
4. Confirm no build output or compiler temporary file is placed in `/tmp`.

If configuration resolution or either build fails, do not commit or present
the images as installable; diagnose the focused failure first.

## Acceptance criteria

- The four requested symbols resolve to built-ins and bridge remains modular.
- The obsolete init module loads are absent.
- Kernel, boot, and vendor builds succeed with matching module versions.
- The Orange Pi 5 DTB and existing GMS/USB-host configuration are preserved.
- Each affected Git repository records a concise, reviewable commit because
  the kernel and device configuration are separate repositories.

## Commit boundary

The logical slice spans two independently versioned repositories. Commit the
kernel defconfig change in `android_kernel_rk_opi`, then commit the device init
change and delivery artifacts in `device/opi/opi5_pro`, after the combined
build and validation pass.
