# Build Android runtime facilities into the kernel

Product ID: `orange-pi-android-tv`

Kernel parent commit: `18bfb0d5d522e73030ae8674ba00d9bfaa3469d8`

Device parent commit: `9e9b4cc6dd78939d8f0f68c9f2bce84a29f9ab9b`

## Objective

Make the INET socket diagnostic handlers and Android virtual-input facility
available from kernel initialization, without relying on hardware uevents or
Android init loading modules from `/vendor`.

## Scope

- Build `INET_DIAG`, `INET_TCP_DIAG`, `INET_UDP_DIAG`, and `INPUT_UINPUT` into
  the Orange Pi 5 kernel.
- Remove the superseded `inet_diag.ko` and `tcp_diag.ko` init actions.
- Rebuild the kernel, matching modules, and Android boot/vendor images.
- Preserve the existing Orange Pi 5 DTB selection and userdata.

## Non-scope

- Keep `BRIDGE` modular.
- Keep raw, packet, Unix, and netlink diagnostic handlers modular.
- Do not change netd behavior, log levels, USB mode, GMS, or application data.
- Do not flash an attached drive without a separate user request.

## Slice index

1. [Provide built-in socket diagnostics and uinput](20260824221512_builtin_android_runtime_facilities_slice_01.md)
