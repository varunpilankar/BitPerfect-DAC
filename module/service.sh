#!/system/bin/sh
MODDIR=${0%/*}
STATE=/data/adb/usb_dac_bitperfect
while [ "$(getprop sys.boot_completed)" != "1" ]; do sleep 2; done
sleep 10
if pidof audioserver >/dev/null 2>&1 && dumpsys media.audio_flinger 2>/dev/null | grep -q "^Output thread"; then rm -f "$MODDIR/.boot_fail"; fi
# boot self-check for bpverify
{
  echo "boot check $(date)"
  echo "overlay files in module: $(find $MODDIR/system -name '*.xml' 2>/dev/null | tr '\n' ' ')"
  echo "live policy has pinned hifi_playback: $(grep -c 'name="hifi_playback"[^>]*><profile' /vendor/etc/audio_policy_configuration.xml)"
  echo "live policy deep_buffer in USB routes: $(grep -A1 'sink="USB' /vendor/etc/audio_policy_configuration.xml | grep -c deep_buffer)"
  grep -E ' (/vendor|/system) ' /proc/mounts | grep -v -E 'erofs|ext4 ro' | head -5
} > "$STATE/boot.log" 2>&1
[ -f "$STATE/auto" ] && "$MODDIR/system/bin/bpfollow" &
