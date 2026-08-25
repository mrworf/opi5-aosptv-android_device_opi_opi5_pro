# Load socket diagnostic modules during boot

Product ID: `orange-pi-android-tv`

Parent commit: `b3f0b794f61421e24445880f1f4d041f88a67841`

## Objective

Load the already-packaged `inet_diag.ko` and `tcp_diag.ko` modules after the
vendor filesystem is mounted so Android netd can collect live TCP socket
information without emitting `ENOENT` every 30 seconds.

## Scope

- Add an explicit Orange Pi init action for the two required modules.
- Preserve the existing kernel, vendor modules, networking behavior, userdata,
  and netd polling behavior.
- Build and inspect a replacement `vendor.img`, which owns both the init file
  and the already-matched modules. No kernel or boot rebuild is required.

## Non-scope

- Suppressing successful netd binder-call INFO messages.
- Loading unrelated diagnostic modules.
- Changing the kernel configuration, netd, ConnectivityService, or polling
  intervals.
- Flashing the image or rebooting the device without a separate user action.

## Evidence and decision

The flashed vendor partition contains both modules and declares them in
`/vendor/lib/modules/modules.load`, but no boot action consumes that file.
Neither module was present in `/proc/modules`. Loading `inet_diag` followed by
`tcp_diag` at runtime made `dumpsys netd tcp_socket_info` return current socket
statistics and eliminated the immediate `ENOENT` failure.

Hardware modalias handling cannot solve this case because socket diagnostic
families do not produce a USB or other hardware uevent. The init action uses
Android init's built-in `insmod`, avoiding a shell service and the malformed
`modules.softdep` warnings produced by Toybox `modprobe` on this image.

Build dependency inspection confirmed that `device.mk` installs the init file
at `/vendor/etc/init/hw/init.opi5.rc`. Consequently this is a vendor-only image
change; the attempted `bootimage` target correctly performed zero build steps.

## Slice index

1. [Load TCP diagnostic modules after mounting vendor](20260824215740_load_socket_diag_modules_slice_01.md)
