#!/system/bin/sh
# KernelSU-Next Manager Auto-Crowning Guard for Samsung One UI 4.1
# Author: Antigravity & Q.S@RDOR

while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 1
done

sleep 1

for pkg in yhaxhr.birgvn.bmwbne io.github.tiann.kernelsu com.rifsxd.ksunext; do
    raw=$(pm list packages -U "$pkg" 2>/dev/null)
    if [ -n "$raw" ]; then
        uid=$(echo "$raw" | grep -o 'uid:[0-9]*' | head -n 1 | cut -d: -f2)
        if [ -n "$uid" ]; then
            /data/adb/ksu/bin/test_ksu "$uid" 2>/dev/null || /system/bin/test_ksu "$uid" 2>/dev/null
            break
        fi
    fi
done
