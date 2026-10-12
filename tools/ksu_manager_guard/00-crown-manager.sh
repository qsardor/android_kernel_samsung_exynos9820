#!/system/bin/sh
# KernelSU-Next Manager Universal Auto-Crowning Guard for Samsung One UI 4.1
# Created by Antigravity & Q.S@RDOR

while [ "$(getprop sys.boot_completed)" != "1" ]; do
    sleep 1
done
sleep 2

# 1. Universal dynamic discovery via unique FlashModule component
pkg=$(dumpsys package 2>/dev/null | grep 'FlashModule' | head -n 1 | awk '{print $2}' | cut -d/ -f1)

# 2. Fallback to known package names if dumpsys is busy
if [ -z "$pkg" ]; then
    for candidate in jfbdoq.homlpj.smcrpi yhaxhr.birgvn.bmwbne io.github.tiann.kernelsu com.rifsxd.ksunext; do
        if pm path "$candidate" >/dev/null 2>&1; then
            pkg="$candidate"
            break
        fi
    done
fi

if [ -n "$pkg" ]; then
    raw=$(dumpsys package "$pkg" 2>/dev/null | grep 'userId=' | head -n 1)
    uid=${raw#*userId=}
    uid=${uid%% *}
    if [ -n "$uid" ]; then
        echo "[+] Crowning manager package: $pkg (UID: $uid)"
        /data/adb/ksu/bin/test_ksu "$uid"
    fi
fi
