#!/system/bin/sh
# Shared helpers (sourced by customize.sh, bprate, bpcheck)
BB=""
for b in /data/adb/magisk/busybox /data/adb/ksu/bin/busybox /data/adb/ap/bin/busybox; do
  [ -x "$b" ] && BB="$b" && break
done
awkc() { if [ -n "$BB" ]; then "$BB" awk "$@"; else awk "$@"; fi; }

# real path ($1) -> overlay path inside module dir ($2)
modpath() {
  case "$1" in
    /system/*) echo "$2/system${1#/system}" ;;
    *) echo "$2/system$1" ;;
  esac
}

# Rewrite samplingRates inside USB *source* mixPorts only (skips BIT_PERFECT ports).
# $1=src $2=dst $3=rate
patch_policy() {
  tdb=1; [ -f /data/adb/usb_dac_bitperfect/keep_deep_buffer ] && tdb=0
  awkc -v rate="$3" -v tdb="$tdb" '
  BEGIN { inb = 0; inr = 0 }
  {
    line = $0
    # drop deep_buffer from the USB routes so media lands on the pinned hifi_playback output (48k/16-bit deep_buffer otherwise wins)
    if (tdb == 1) {
      if (line ~ /<route/ && line ~ /sink="USB (Device|Headset) Out"/) inr = 1
      if (inr && match(line, /sources="[^"]*"/)) {
        src = substr(line, RSTART + 9, RLENGTH - 10); n = split(src, p, ","); out = ""
        for (i = 1; i <= n; i++) if (p[i] != "deep_buffer") out = (out == "" ? p[i] : out "," p[i])
        line = substr(line, 1, RSTART + 8) out "\"" substr(line, RSTART + RLENGTH)
      }
      if (inr && line ~ /\/>/) inr = 0
    }
    # Qualcomm dynamic mixPort without profiles: give it one fixed profile (otherwise policy picks the DAC maximum)
    if (!inb && line ~ /<mixPort/ && line ~ /name="hifi_playback"/ && line ~ /\/>[ \t]*$/ && line !~ /profile/) {
      sub(/[ \t]*\/>[ \t]*$/, "><profile name=\"\" format=\"AUDIO_FORMAT_PCM_32_BIT\" samplingRates=\"" rate "\" channelMasks=\"AUDIO_CHANNEL_OUT_STEREO\"/></mixPort>", line)
      print line; next
    }
    if (!inb && line ~ /<mixPort/ && line !~ /role="sink"/ && tolower(line) ~ /name="[^"]*usb[^"]*"/ && line !~ /BIT_PERFECT/) inb = 1
    if (inb) {
      if (line ~ /samplingRates="[^"]*"/) sub(/samplingRates="[^"]*"/, "samplingRates=\"" rate "\"", line)
      if (line ~ /<\/mixPort>/ || (line ~ /<mixPort/ && line ~ /\/>[ \t]*$/)) inb = 0
    }
    print line
  }' "$1" > "$2"
}

# sanity: same line count + same mixPort count
patch_ok() {
  [ "$(wc -l < "$1")" = "$(wc -l < "$2")" ] || return 1
  [ "$(grep -c '<mixPort' "$1")" = "$(grep -c '<mixPort' "$2")" ] || return 1
  return 0
}

# ---- v0.2: auto-follow helpers ----
usb_card() { for c in /proc/asound/card*; do [ -f "$c/usbid" ] && { echo "$c"; return; }; done; }

dump_af() { if [ -n "$TRACK_DUMP_FILE" ]; then cat "$TRACK_DUMP_FILE"; else dumpsys media.audio_flinger 2>/dev/null; fi; }

# Prints the source rate of the active track(s) on the USB output thread, only if exactly one distinct rate.
track_rate() {
  dump_af | awkc '
  BEGIN { split("8000 11025 12000 16000 22050 24000 32000 44100 48000 88200 96000 176400 192000 352800 384000", a, " "); for (i in a) known[a[i]] = 1 }
  /^(Output|Playback|Direct|Offload|MMAP)[A-Za-z ]*thread/ { inusb = 0 }
  /Output device/ && /USB/ { inusb = 1 }
  inusb && ($3 == "yes" || $2 == "yes") { for (i = 8; i <= NF; i++) if ($i in known) { seen[$i] = 1; break } }
  END { n = 0; for (r in seen) { n++; rate = r }; if (n == 1) print rate }'
}

# rate_supported <rate> <stream0 file>
rate_supported() {
  grep "Rates:" "$2" 2>/dev/null | awkc -v r="$1" '
    { s = $0; gsub(/[^0-9 ]/, " ", s); n = split(s, t, " ")
      if ($0 ~ /continuous/) { if (n >= 2 && r + 0 >= t[1] + 0 && r + 0 <= t[2] + 0) ok = 1 }
      else for (i = 1; i <= n; i++) if (t[i] == r) ok = 1 }
    END { exit ok ? 0 : 1 }'
}

# pick_rate <track rate> <stream0 file>: same rate if the DAC has it, else x2/x4/x8 multiple
pick_rate() {
  for m in 1 2 4 8; do
    c=$(( $1 * m ))
    case $c in
      44100|48000|88200|96000|176400|192000|352800|384000)
        rate_supported "$c" "$2" && { echo "$c"; return; } ;;
    esac
  done
}

# Prints "rate=<Hz> format=<HAL format> flags=<flags>" for every AudioFlinger output thread routed to USB
usb_thread_info() {
  dump_af | awkc '
  function flush() { if (blk ~ /AUDIO_DEVICE_OUT_USB/ && r != "") print "thread=" nm " rate=" r " format=" f " flags=" fl; blk=""; r=""; f=""; fl="" }
  /^Output thread/ { flush(); nm=$0; sub(/.*name /,"",nm); sub(/,.*/,"",nm) }
  { blk = blk $0 }
  /^  Sample rate:/ { r=$3 }
  /^  HAL format:/ { f=$4 }
  /^  AudioStreamOut:/ { fl=$0; sub(/.*flags /,"",fl) }
  END { flush() }'
}

# Raw track-table rows (header + rows) of every AudioFlinger output thread routed to USB; shows rate, gain (G/L/R dB) per track
usb_tracks() {
  dump_af | awkc '
  function flush() { if (blk ~ /AUDIO_DEVICE_OUT_USB/ && rows != "") print "[" nm "]\n" rows; blk=""; rows=""; intab=0 }
  /^Output thread/ { flush(); nm=$0; sub(/.*name /,"",nm); sub(/,.*/,"",nm) }
  { blk = blk $0 }
  /Type +Id +Active/ { intab=1; hdr=$0; sub(/^ +/,"",hdr); rows = rows "  " substr(hdr,1,200) "\n"; next }
  intab && NF == 0 { intab=0 }
  intab && /[0-9]/ { r=$0; sub(/^ +/,"",r); rows = rows "  " substr(r,1,200) "\n" }
  END { flush() }'
}

# ================= v0.7: single-dump probe, status line, faster switching =================
# One dumpsys -> one line: thr= mrate= mfmt= active= trate= tfmt= tgain= tcount=   (best USB thread: active track > not in standby > 32-bit)
af_probe() {
  dump_af | awkc '
  function flush(   sc) {
    if (inusb) {
      sc = (nact > 0) * 100 + (stby == "no") * 10 + (mf ~ /32/)
      if (sc > best) { best = sc; out = "thr=" nm " mrate=" mr " mfmt=" mf " busy=" (stby == "no" ? 1 : 0) " active=" (nact > 0 ? 1 : 0) " trate=" trt " tfmt=" tft " tgain=" tg " tpvol=" tpv " tcount=" nact }
    }
    inusb = 0; nm = ""; mr = ""; mf = ""; stby = ""; nact = 0; trt = "-"; tft = "-"; tg = "-"; tpv = "-"; intab = 0
  }
  BEGIN { best = -1; out = "none"; trt = "-"; tft = "-"; tg = "-"; tpv = "-"
          split("8000 11025 12000 16000 22050 24000 32000 44100 48000 88200 96000 176400 192000 352800 384000", a, " "); for (i in a) known[a[i]] = 1 }
  /^Output thread/ { flush(); expect = 0; nm = $0; sub(/.*name /, "", nm); sub(/,.*/, "", nm); next }
  /Tracks of which/ { expect = 1; next }
  /^  Standby:/ && stby == "" { stby = $2 }
  /^  Sample rate:/ { mr = $3 }
  /^  HAL format:/ { mf = $4; gsub(/[()]/, "", mf) }
  /Output devices/ && /USB/ { inusb = 1 }
  expect && /Active/ { expect = 0; intab = 1; next }
  intab && NF == 0 { intab = 0; next }
  intab && inusb {
    # Row layout (Android 16): [Type may be blank] Id Active Client(pid/ uid) Session PortId S Flags Format ChnMask SRate ST Usg CT G L R VS PortVol ...
    ai = 0; for (i = 1; i <= 4 && i <= NF; i++) if ($i == "yes" || $i == "no") { ai = i; break }
    if (!ai || $ai != "yes") next
    c = ai + 1; if ($c ~ /\/$/) c = ai + 2
    ri = c + 7
    if (!($ri in known)) { ri = c + 6; fi = c + 4 } else { fi = c + 5 }
    if (!($ri in known)) { ri = 0; for (i = c; i <= NF; i++) if ($i in known) { ri = i; break }; fi = 0 }
    if (!ri) next
    r = $ri; f = (fi ? $fi : "-"); gd = $(ri + 4); pv = $(ri + 8)
    nact++
    if (trt == "-") { trt = r; tft = f; tg = gd; tpv = pv } else if (trt != r) trt = "multi"
  }
  END { flush(); print out }'
}

load_probe() { thr=; mrate=; mfmt=; busy=0; active=0; trate=-; tfmt=-; tgain=-; tpvol=-; tcount=0
  for kv in $(af_probe); do case "$kv" in *=*) eval "${kv%%=*}='${kv#*=}'" ;; esac; done; }

# bit depth number from a HAL/AudioFlinger format name or hex code
bits_num() {
  case "$1" in
    *PCM_16_BIT*) echo 16 ;; *PCM_24_BIT_PACKED*|*PCM_8_24_BIT*) echo 24 ;; *PCM_32_BIT*|*PCM_FLOAT*) echo 32 ;;
    *) case "$(echo "$1" | sed 's/^0x//; s/^0*//')" in 1) echo 16 ;; 3|5) echo 32 ;; 4|6) echo 24 ;; *) echo 0 ;; esac ;;
  esac
}
bits_label() {
  case "$1" in
    *PCM_FLOAT*) echo "32-bit float" ;;
    *PCM_8_24_BIT*) echo "24-bit (8.24)" ;;
    *) b=$(bits_num "$1"); [ "$b" = 0 ] && echo "unknown fmt $1" || echo "${b}-bit" ;;
  esac
  case "$1" in 5|0x5|00000005) ;; esac
}
khz() { awkc -v r="$1" 'BEGIN { printf "%g kHz", r / 1000 }'; }
kbps() { echo $(( $1 * $2 * 2 / 1000 )); }

# Human status line from the current probe (call load_probe first)
status_line() {
  [ "$thr" = "" ] && { echo "No USB output thread (DAC not routed/connected)"; return; }
  mb=$(bits_num "$mfmt")
  m="Mixer $(khz "$mrate") / ${mb}-bit container ($(kbps "$mrate" "$mb") kbps)"
  if [ "$active" != 1 ]; then
    if [ "$busy" = 1 ]; then echo "$m | playing, but source track not parsed (run: bpdump)"; else echo "$m | idle (no active track)"; fi
    return
  fi
  if [ "$trate" = multi ]; then echo "$m | several tracks at different rates (system sound mixing)"; return; fi
  tb=$(bits_num "$tfmt"); tl=$(bits_label "$tfmt"); [ "$tfmt" = - ] && { tb=0; tl="?"; }
  s="Source $(khz "$trate") / $tl ($([ "$tb" -gt 0 ] && kbps "$trate" "$tb" || echo ?) kbps)"
  v="rate-matched"; [ "$trate" != "$mrate" ] && v="RESAMPLED $(khz "$trate")->$(khz "$mrate")"
  gn="gain ${tgain} dB"; case "$tgain" in 0|0.0|0.00|-) ;; *) v="$v, VOLUME ${tgain} dB: set media volume to MAX" ;; esac
  case "$tfmt" in *5|*FLOAT*) v="$v, float source" ;; esac
  echo "$m | $s | $gn | $v"
}

# rewrite overlay for rate $1 from pristine copies and restart audioserver
apply_rate() {
  _M=/data/adb/modules/usb_dac_bitperfect
  while IFS='|' read -r real orig; do
    dst=$(modpath "$real" "$_M"); [ -f "$dst" ] || continue
    patch_policy "$orig" "$_M/.tmp.xml" "$1"
    patch_ok "$orig" "$_M/.tmp.xml" && cat "$_M/.tmp.xml" > "$dst"
    rm -f "$_M/.tmp.xml"
  done < "$_M/orig.list"
  echo "$1" > /data/adb/usb_dac_bitperfect/rate
  setprop ctl.restart audioserver 2>/dev/null || pkill audioserver
}

now_ms() { t=$(date +%s%N 2>/dev/null); case "$t" in *N*|"") echo $(( $(date +%s) * 1000 )) ;; *) echo $(( t / 1000000 )) ;; esac; }
nap() { sleep "$1" 2>/dev/null || sleep 1; }

# true if the file already carries our edits (single-line hifi_playback with a profile)
looks_patched() { grep -q 'name="hifi_playback"[^>]*><profile' "$1" 2>/dev/null; }

# Names of effects that are ENABLED on any output (these alter the signal)
active_effects() {
  { if [ -n "$POLICY_DUMP_FILE" ]; then cat "$POLICY_DUMP_FILE"; else dumpsys media.audio_policy 2>/dev/null; fi; } | awkc '
    /Music Effect\?/ && /; Enabled;/ { n = $0; sub(/^[^"]*"/, "", n); sub(/".*/, "", n); print n }' | sort -u | tr '\n' ',' | sed 's/,$//'
}

# Remove pid/uid pairs and kernel pointers from text destined for public issues
sanitize_report() { sed -E 's#[0-9]+/ *[0-9]+#<pid>/<uid>#g; s#0x[0-9a-f]{8,}#<ptr>#g'; }
