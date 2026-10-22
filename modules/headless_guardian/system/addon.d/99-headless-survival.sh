#!/sbin/sh
#
# ADDOND_VERSION=2
#
# /system/addon.d/99-headless-survival.sh
# Headless LineageOS 23.2 & KernelSU-Next Survival Hook
# Automatically preserves custom headless kernel and persistent ADB across OTA/ROM updates.
# Attribution: Created by Antigravity & Q.S@RDOR
#

. /tmp/backuptool.functions

BOOT_DEV="/dev/block/by-name/boot"
BACKUP_PATH="/tmp/headless_boot_backup.img"
DATA_BACKUP="/data/adb/headless_guardian/boot_backup.img"

case "$1" in
  backup)
    echo "[headless-survival] Backing up active headless kernel..."
    if [ -b "$BOOT_DEV" ]; then
      dd if="$BOOT_DEV" of="$BACKUP_PATH" bs=4096 2>/dev/null
    elif [ -f "$DATA_BACKUP" ]; then
      cp -f "$DATA_BACKUP" "$BACKUP_PATH"
    fi
  ;;
  restore)
    if [ -f "$C/$S/addon.d/99-headless-survival.sh" ]; then
      restore_file "$S/addon.d/99-headless-survival.sh"
    fi
  ;;
  pre-backup)
    # Stub
  ;;
  post-backup)
    # Stub
  ;;
  pre-restore)
    # Stub
  ;;
  post-restore)
    echo "[headless-survival] Re-flashing headless kernel with KernelSU-Next to boot partition..."
    if [ -f "$BACKUP_PATH" ] && [ -b "$BOOT_DEV" ]; then
      dd if="$BACKUP_PATH" of="$BOOT_DEV" bs=4096 2>/dev/null
      sync
      echo "[headless-survival] Headless kernel successfully restored to $BOOT_DEV!"
    elif [ -f "$DATA_BACKUP" ] && [ -b "$BOOT_DEV" ]; then
      dd if="$DATA_BACKUP" of="$BOOT_DEV" bs=4096 2>/dev/null
      sync
      echo "[headless-survival] Headless kernel successfully restored from $DATA_BACKUP!"
    else
      echo "[headless-survival] ERROR: No backup image found to restore!"
    fi
  ;;
esac
