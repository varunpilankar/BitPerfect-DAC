#!/system/bin/sh
SKIPUNZIP=0
ILOG=/data/local/tmp/bitperfect_install.log
: > "$ILOG"
_up() { ui_print "$1"; echo "$1" >> "$ILOG"; }
. "$MODPATH/common.sh"
STATE=/data/adb/usb_dac_bitperfect
RATE=44100
[ -f "$STATE/rate" ] && RATE=$(cat "$STATE/rate")
REPORT=/data/local/tmp/bitperfect_install_report.txt
OLD=${BP_OLD:-/data/adb/modules/usb_dac_bitperfect}
FP=$(getprop ro.build.fingerprint)
ROOTS=${BP_ROOTS:-"/vendor/etc /system/etc /odm/etc /product/etc"}

_up "- USB DAC Bit-Perfect Helper v0.9.1 (experimental)"
[ "$API" -ge 36 ] || _up "! Built for Android 16 (API 36); this device is API $API"
mkdir -p "$MODPATH/orig" "$STATE"
: > "$MODPATH/orig.list"; : > "$REPORT"
N=0; SEEN=" "
for f in $(find $ROOTS -name '*audio_policy*.xml' 2>/dev/null); do
  [ -f "$f" ] || continue
  real=$(readlink -f "$f" 2>/dev/null); [ -n "$real" ] || real=$f
  case "$SEEN" in *" $real "*) continue ;; esac
  SEEN="$SEEN$real "
  usbports=$(grep -i '<mixPort' "$real" | grep -ic -E 'usb|hifi_playback')
  echo "## $real (usb mixPort lines: $usbports)" >> "$REPORT"
  grep -n -i usb "$real" | head -40 >> "$REPORT"
  if [ "$usbports" = 0 ]; then _up "  skip $real: no USB/hifi_playback mixPort"; continue; fi
  case "$real" in
    /vendor/*|/system/*) ;;
    *) if [ -z "$BP_TEST" ]; then _up "  skip $real: partition not overlayable"; continue; fi ;;
  esac
  # Find the PRISTINE file. If this module is already installed, the live file is our own patched overlay.
  safe=$(echo "$real" | tr '/' '_'); src=""
  if [ -f "$OLD/orig/$safe" ] && [ "$(cat "$OLD/orig.fp" 2>/dev/null)" = "$FP" ] && ! looks_patched "$OLD/orig/$safe"; then
    src="$OLD/orig/$safe"; _up "  reusing pristine copy of $real"
  elif ! looks_patched "$real"; then src=$real
  else
    for mp in /debug_ramdisk/.magisk/mirror /sbin/.magisk/mirror /.magisk/mirror; do
      [ -f "$mp$real" ] && ! looks_patched "$mp$real" && { src="$mp$real"; break; }
    done
  fi
  if [ -z "$src" ]; then
    _up "! $real is already patched and no pristine copy was found."
    _up "! Remove this module, reboot, then install again."
    NEEDCLEAN=1
    continue
  fi
  tmp="$MODPATH/.tmp.xml"
  patch_policy "$src" "$tmp" "$RATE"
  if cmp -s "$src" "$tmp"; then
    _up "  skip $real: nothing to rewrite (no static USB rates, no empty hifi_playback port)"
    grep -i '<mixPort' "$real" | grep -i usb | head -2 | sed 's/^ *//' | cut -c1-100 | while read -r l; do _up "    $l"; done
    rm -f "$tmp"; continue
  fi
  if ! patch_ok "$src" "$tmp"; then _up "! sanity check failed: $real"; rm -f "$tmp"; continue; fi
  cp "$src" "$MODPATH/orig/$safe"
  dst=$(modpath "$real" "$MODPATH")
  mkdir -p "${dst%/*}"; mv "$tmp" "$dst"
  case "$real" in /vendor/*) ctx=u:object_r:vendor_configs_file:s0 ;; *) ctx=u:object_r:system_file:s0 ;; esac
  set_perm "$dst" 0 0 0644 "$ctx"
  echo "$real|$MODPATH/orig/$safe" >> "$MODPATH/orig.list"
  _up "  patched: $real -> ${RATE} Hz"
  N=$((N+1))
done
echo "$FP" > "$MODPATH/orig.fp"
cp "$REPORT" /sdcard/Download/bitperfect_install_report.txt 2>/dev/null
cp "$ILOG" "$MODPATH/install.log" 2>/dev/null
cp "$ILOG" /sdcard/Download/bitperfect_install.log 2>/dev/null

[ "$NEEDCLEAN" = 1 ] && abort "! Aborted: installing now would drop the working overlay. Remove the module, reboot, install again."
if [ "$N" -eq 0 ]; then
  _up "! No static USB rates to rewrite: installed in DIAGNOSTIC mode (system untouched)."
  _up "! Run in a root terminal: bpdiag   and share the output."
else
  [ -f "$STATE/rate" ] || touch "$STATE/auto"
  echo "$RATE" > "$STATE/rate"
fi
set_perm_recursive "$MODPATH" 0 0 0755 0644
for s in system/bin/bpcheck system/bin/bprate system/bin/bpfollow system/bin/bpdiag system/bin/bpoffload system/bin/bpstatus system/bin/bpdump system/bin/bpverify system/bin/bpreport post-fs-data.sh service.sh uninstall.sh; do
  set_perm "$MODPATH/$s" 0 0 0755
done
_up "- Done. Reboot, plug DAC, then: su -c bpcheck"
