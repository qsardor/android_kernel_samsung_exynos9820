#!/system/bin/sh
MODDIR=${0%/*}

RESETPROP="/data/adb/ksud resetprop"
if [ ! -x "$RESETPROP" ]; then
  RESETPROP="resetprop"
fi

$RESETPROP -n persist.sys.usb.config adb
$RESETPROP -n sys.usb.config adb
$RESETPROP -n ro.adb.secure 0
$RESETPROP -n ro.debuggable 1

mkdir -p /data/adb/headless_guardian
BOOT_DEV="/dev/block/by-name/boot"
if [ -b "$BOOT_DEV" ]; then
  if [ ! -f /data/adb/headless_guardian/boot_backup.img ] || [ $(wc -c < /data/adb/headless_guardian/boot_backup.img) -lt 30000000 ]; then
    dd if="$BOOT_DEV" of=/data/adb/headless_guardian/boot_backup.img bs=4096 2>/dev/null
  fi
fi

mount -o remount,rw / 2>/dev/null || true
if [ -d /system/addon.d ] && [ ! -f /system/addon.d/99-headless-survival.sh ]; then
  cp -f "$MODDIR/system/addon.d/99-headless-survival.sh" /system/addon.d/99-headless-survival.sh 2>/dev/null || true
  chmod 755 /system/addon.d/99-headless-survival.sh 2>/dev/null || true
fi
