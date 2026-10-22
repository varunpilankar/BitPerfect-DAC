# Architecture

## Data flow on the reference device

```
App (AudioTrack: 96 kHz, PCM float)
  -> AudioFlinger track mixer      (resamples to the output thread's rate)
     -> output thread AudioOut_xx  (one fixed rate + format per thread)
        -> audio HAL stream        (Qualcomm primary HAL; flags NONE = "hifi_playback" mix port)
           -> USB Headset Out      (Qualcomm USB offload, or host ALSA driver)
              -> DAC
```

Which output thread a track gets is chosen by the audio policy from `/vendor/etc/audio_policy_configuration.xml` (the dump line `Config source:` confirms the file). Relevant objects:

| Policy object | Role | Stock behaviour on the reference device |
|---|---|---|
| `primary output` (FAST\|PRIMARY) | low-latency / system sounds | 48 kHz, 16-bit; also carried USB sonification |
| `deep_buffer` (DEEP_BUFFER) | power-saving media | 48 kHz, 16-bit; **routed to USB** |
| `hifi_playback` (flags NONE, **no profile**) | Qualcomm hi-fi path | *dynamic*: takes the DAC maximum, **384 kHz / 32-bit** |
| `direct_pcm` (DIRECT) | direct PCM up to 192 kHz | exists, not used by the captured Apple Music session |
| `USB Device Out`, `USB Headset Out` | device ports | dynamic profiles from the DAC |

## What the overlay changes

`module/common.sh: patch_policy` is a single `awk` pass over the pristine XML:

1. `<mixPort name="hifi_playback" ... />` (self-closing, no profile) becomes
   `<mixPort ...><profile name="" format="AUDIO_FORMAT_PCM_32_BIT" samplingRates="<RATE>" channelMasks="AUDIO_CHANNEL_OUT_STEREO"/></mixPort>` on **one line**, so line counts are preserved.
2. For `<route ... sink="USB Device Out|USB Headset Out">`, the token `deep_buffer` is removed from the `sources="..."` list (toggle: `bprate deepbuffer keep|trim`).
3. Any *static* USB source mix port (`name` contains `usb`, not `role="sink"`, not `BIT_PERFECT`) has its `samplingRates` rewritten. This was the v0.1 approach and does nothing on the reference device.

`patch_ok` rejects a result whose line count or `<mixPort` count differs from the pristine file.

Resulting expectations (unverified end to end): the USB music thread opens at `<RATE>` in 32-bit. Android mixes in float and converts to the 32-bit container; for integer sources up to 24 bit at unity gain and an identical rate this is lossless in principle.

## Files the installer touches

`customize.sh` looks for `*audio_policy*.xml` under `/vendor/etc /system/etc /odm/etc /product/etc`, resolves symlinks, and only overlays files under `/vendor` or `/system`. For every candidate it reports **why** it patched or skipped it (also saved to `install.log`).

Pristine source selection (added in v0.8):

1. Saved pristine copy from a previously installed version, only if the build fingerprint matches;
2. else the live file, **only if it does not already carry our edit** (`looks_patched`);
3. else a Magisk mirror copy;
4. else abort, so a working older install is not replaced by an empty one.

## Runtime components

| Component | Language | Role |
|---|---|---|
| `common.sh` | sh + awk | all parsing/patching logic; sourced by everything else |
| `customize.sh` | sh | installer |
| `post-fs-data.sh` | sh | boot guard counter; optional `resetprop` for `bpoffload` |
| `service.sh` | sh | clears boot counter after audio is up, writes `boot.log`, starts `bpfollow` |
| `bpfollow` | sh | daemon: probe, debounce (2 readings), switch, wait for audioserver, log timings |
| `bprate`, `bpstatus`, `bpcheck`, `bpverify`, `bpdiag`, `bpdump`, `bpoffload` | sh | user tools |

### The probe (`af_probe`)

One `dumpsys media.audio_flinger` per call. For every `Output thread` whose `Output devices` line mentions USB it records standby state, mixer sample rate, HAL format and active tracks. It then reports the "best" thread: one with an active track, else one not in standby, else a 32-bit one. Track rows are parsed by **anchoring on the `yes`/`no` Active token**, because on Android 16:

- the `Type` column is blank for ordinary tracks;
- `Client(pid/uid)` prints as `4990/  10198` (two tokens);
- `PortVol dB` is one value under a two-word header.

Offsets from the `SRate` token: `+4` = `G db`, `+8` = `PortVol dB`. Format codes seen: `00000005` = `PCM_FLOAT`, `00000001` = `PCM_16_BIT`, `00000003` = `PCM_32_BIT`.

### Auto-follow loop (`bpfollow`)

```
loop while $STATE/auto exists:
  probe -> write status file (+ optional notification)
  if no active single-rate track: sleep 1 s
  want = pick_rate(track rate, DAC rates)   # same rate, else x2/x4/x8 if the DAC lists it
  if want != configured rate: need 2 consecutive readings (~0.5-0.8 s)
  apply_rate(want)  # regenerate overlay from pristine copies, `setprop ctl.restart audioserver`
  wait until audioserver + AudioFlinger answer, log "detect X ms, restart Y ms"
  safety: >6 switches in 120 s -> disable auto-follow
```

### Boot guard

`post-fs-data.sh` increments `.boot_fail`; `service.sh` deletes it ~10 s after `sys.boot_completed` if `audioserver` runs and AudioFlinger lists output threads. A counter of 2 at boot start disables the module.

## State and log files

| Path | Meaning |
|---|---|
| `/data/adb/usb_dac_bitperfect/rate` | configured mixer rate (Hz) |
| `.../auto`, `.../notify`, `.../keep_deep_buffer`, `.../usb_offload_off` | feature flags (file exists = on) |
| `.../status` | last status line written by `bpfollow` |
| `.../follow.log`, `.../follow.pid`, `.../boot.log` | daemon log, pid, boot self-check |
| `<module>/orig/`, `orig.list`, `orig.fp` | pristine policy copies, `real-path|copy` list, build fingerprint |
| `<module>/install.log` | installer decisions |
| `/data/local/tmp/bitperfect_install*.{log,txt}`, `/sdcard/Download/` copies | installer report |

## Known technical limits

- AudioFlinger offers **one rate per output thread**; there is no per-track rate switching. Hence the restart-based follow design.
- The module cannot make an app request `BIT_PERFECT`; it only changes what the shared mixer does.
- It cannot see inside the apps (their own DSP, volume, resampling).
- Edits are tied to Qualcomm/OnePlus naming (`hifi_playback`). Other vendors will differ.
