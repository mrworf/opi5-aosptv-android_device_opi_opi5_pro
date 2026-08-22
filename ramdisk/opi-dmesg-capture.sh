#!/vendor/bin/sh

# Save the complete current kernel ring buffer and the USB probe state before
# following new messages.  This starts after userdata is mounted so early
# DWC3/PHY errors and deferred probes survive power-off.
{
    echo '=== initial dmesg ==='
    /system/bin/dmesg
    echo '=== registered UDCs ==='
    /system/bin/ls -la /sys/class/udc
    echo '=== deferred devices ==='
    /system/bin/cat /sys/kernel/debug/devices_deferred
} > /data/misc/dmesgd/boot-state.log 2>&1

exec /system/bin/dmesg -w > /data/misc/dmesgd/kernel-live.log 2>&1
