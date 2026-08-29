# USB-Wakeable Android TV Sleep

Product ID: `orange-pi-android-tv`

## Goal and slices

Use Android TV's standard deep-standby path, allow all physical USB-A paths to
wake the Orange Pi 5, add immediate Settings-root Sleep, and rename the existing
timer without changing it. The slices are: (01) TvSettings UI, permission,
terminology, and tests; (02) kernel USB wake and DT; (03) removal of the board's
obsolete suspend blocker. Keep auto-suspend, USB host mode/VBUS, matching kernel
modules, Google TV GMS, Ethernet ADB, and the separate Power off action.
Bluetooth wake and Wake-on-LAN are out of scope. No timers, sleeps, polling,
custom suspend services, screen-blanking substitutes, or `s2idle` are allowed.

## Integrated verification

Use `-j26` for all builds. Build boot/system/vendor, inspect image contents and
DTB, preserve rollback images, then provide the exact guarded `pkexec` flash
command for the user. Hardware acceptance proves deep suspend and independent
keyboard/mouse wake across every USB-A port without reboot or USB regressions.
