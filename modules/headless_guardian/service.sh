#!/system/bin/sh
MODDIR=${0%/*}

(
  until [ "$(getprop sys.boot_completed)" = "1" ]; do
    sleep 2
  done

  settings put global adb_enabled 1 2>/dev/null
  settings put global development_settings_enabled 1 2>/dev/null
  settings put global stay_on_while_plugged_in 3 2>/dev/null
  wm dismiss-keyguard 2>/dev/null

  UDC_NAME="10c00000.dwc3"
  CONFIGFS_DIR="/config/usb_gadget/g1"

  while true; do
    CURR_USB=$(getprop sys.usb.config)
    case "$CURR_USB" in
      *adb*)
        ;;
      *)
        setprop sys.usb.config none 2>/dev/null
        sleep 0.2
        setprop sys.usb.config adb 2>/dev/null

        if [ -d "$CONFIGFS_DIR" ] && [ -f "$CONFIGFS_DIR/UDC" ]; then
          ACTUAL_UDC=$(cat "$CONFIGFS_DIR/UDC" 2>/dev/null)
          if [ -z "$ACTUAL_UDC" ]; then
            echo "$UDC_NAME" > "$CONFIGFS_DIR/UDC" 2>/dev/null
          fi
        fi
        ;;
    esac

    if ! pgrep -x adbd >/dev/null 2>&1; then
      start adbd 2>/dev/null
    fi

    wm dismiss-keyguard 2>/dev/null
    sleep 3
  done
) &
