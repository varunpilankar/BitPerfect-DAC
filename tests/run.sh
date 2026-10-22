#!/bin/sh
# Offline tests for the pure-text logic (policy patching, dump parsing, status line, rate picking).
# Needs: sh, awk, grep, sed. Run from repo root:  sh tests/run.sh
HERE=$(cd "$(dirname "$0")" && pwd)
FX=$HERE/fixtures
. "$HERE/../module/common.sh"
PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); echo "ok   - $1"; }
bad()  { FAIL=$((FAIL+1)); echo "FAIL - $1"; }
check() { if [ "$2" = "$3" ]; then ok "$1"; else bad "$1 (expected '$3', got '$2')"; fi; }
has()  { case "$2" in *"$3"*) ok "$1" ;; *) bad "$1 (missing '$3' in '$2')" ;; esac; }
hasnt(){ case "$2" in *"$3"*) bad "$1 (unexpected '$3' in '$2')" ;; *) ok "$1" ;; esac; }
T=$(mktemp -d)

patch_policy "$FX/policy_stock.xml" "$T/p.xml" 44100
patch_ok "$FX/policy_stock.xml" "$T/p.xml" && ok "patch keeps line + mixPort counts" || bad "patch_ok"
has  "hifi_playback gets one static profile" "$(cat $T/p.xml)" 'name="hifi_playback" role="source"><profile name="" format="AUDIO_FORMAT_PCM_32_BIT" samplingRates="44100"'
hasnt "deep_buffer removed from USB Device route" "$(grep -A1 'sink="USB Device Out"' $T/p.xml)" deep_buffer
hasnt "deep_buffer removed from USB Headset route" "$(grep -A1 'sink="USB Headset Out"' $T/p.xml)" deep_buffer
has  "deep_buffer kept on Speaker route" "$(grep -A1 'sink="Speaker"' $T/p.xml)" deep_buffer
has  "sink port untouched" "$(cat $T/p.xml)" 'usb_surround_sound" role="sink"><profile name="" format="AUDIO_FORMAT_PCM_16_BIT" samplingRates="48000"'
looks_patched "$T/p.xml" && ok "looks_patched detects our edit" || bad "looks_patched (patched)"
looks_patched "$FX/policy_stock.xml" && bad "looks_patched (stock)" || ok "looks_patched ignores stock file"
patch_policy "$FX/policy_stock.xml" "$T/p96.xml" 96000
has  "rate is configurable" "$(cat $T/p96.xml)" 'samplingRates="96000"'

TRACK_DUMP_FILE=$FX/flinger_playing_384k.txt; export TRACK_DUMP_FILE
load_probe
check "384k case: thread"      "$thr"    AudioOut_5D
check "384k case: mixer rate"  "$mrate"  384000
check "384k case: source rate" "$trate"  96000
check "384k case: source fmt"  "$tfmt"   00000005
check "384k case: gain"        "$tgain"  -21
check "384k case: one active"  "$tcount" 1
s=$(status_line)
has "384k case: flags resampling" "$s" "RESAMPLED"
has "384k case: flags volume"     "$s" "VOLUME -21 dB"
has "384k case: float source"     "$s" "float source"
TRACK_DUMP_FILE=$FX/flinger_playing_matched.txt; load_probe; s=$(status_line)
has   "matched case: rate-matched" "$s" "rate-matched"
hasnt "matched case: no resample flag" "$s" "RESAMPLED"
hasnt "matched case: no volume flag"   "$s" "VOLUME"
has   "matched case: 16-bit source"    "$s" "16-bit"
TRACK_DUMP_FILE=$FX/flinger_idle.txt; load_probe; has "idle case" "$(status_line)" "idle"

check "pick 44100" "$(pick_rate 44100 $FX/stream0_dac.txt)" 44100
check "pick 96000" "$(pick_rate 96000 $FX/stream0_dac.txt)" 96000
check "88200 unsupported -> none" "$(pick_rate 88200 $FX/stream0_dac.txt)" ""

POLICY_DUMP_FILE=$FX/policy_effects.txt; export POLICY_DUMP_FILE
check "only enabled effects reported" "$(active_effects)" "Volume listener for Music"

check "sanitize_report strips pid/uid and pointers" "$(printf '  58 yes 4990/  10198 0xb4000072110939f0\n' | sanitize_report)" "  58 yes <pid>/<uid> <ptr>"

rm -rf "$T"
echo; echo "passed=$PASS failed=$FAIL"
[ "$FAIL" = 0 ]
