#!/system/bin/sh
# Boot guard: disable the overlay only after TWO consecutive boots where audio never came up.
MODDIR=${0%/*}
F=$MODDIR/.boot_fail
n=$(cat "$F" 2>/dev/null); n=${n:-0}
if [ "$n" -ge 2 ]; then
  rm -f "$F"
  [ -d "$MODDIR/system" ] && mv "$MODDIR/system" "$MODDIR/system.disabled"
  sed -i 's/^description=.*/description=[DISABLED by boot guard: audio failed to start on 2 boots. Reinstall to re-enable.]/' "$MODDIR/module.prop"
  touch "$MODDIR/disable"
  exit 0
fi
echo $((n+1)) > "$F"
[ -f /data/adb/usb_dac_bitperfect/usb_offload_off ] && resetprop -n vendor.audio.feature.usb_offload.enable false
