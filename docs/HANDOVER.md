# Handover

This document is for the next maintainer. It states what exists, what was proven, what was **not**, and what to do next. Read it together with [ARCHITECTURE.md](ARCHITECTURE.md) and [FINDINGS_OnePlus7.md](FINDINGS_OnePlus7.md).

> **Honest status (module v0.9.1):** experimental. Everything was developed by remote iteration against diagnostic dumps from **one** device. The module has never been confirmed, end to end, to deliver a rate-matched, unity-gain stream to a USB DAC for Apple Music *or* Spotify. See [Open problems](#open-problems).

## 1. The goal

Play Apple Music / Spotify through an external USB DAC on a rooted Android 16 (LineageOS 23.2) phone **without sample-rate conversion in Android**, and make the result verifiable from a terminal (the DAC has no display or LED).

## 2. What Android actually does (summary)

1. Apps write PCM into an `AudioTrack`. Android has an opt-in bit-perfect API (`AudioManager.setPreferredMixerAttributes`, see [AOSP docs](https://source.android.com/docs/core/audio/preferred-mixer-attr)). We found no evidence that Apple Music or Spotify use it: the captured Apple Music track row had `BitPerfect = false`. We could not inspect the apps themselves, and Spotify was never captured.
2. AudioFlinger mixes every track on an **output thread that runs at one fixed sample rate and format**. A track at a different rate is resampled.
3. Which thread/rate is used is decided by the audio policy, from `audio_policy_configuration.xml`. A *mix port without profiles* is "dynamic": the policy gives it the DAC's **maximum** capability.

On the reference device this meant: music went to a flag-less output (`hifi_playback`) opened at **384 kHz / 32-bit**, so a 96 kHz track was resampled 4×, and a 44.1 kHz track by 8.7×. Full evidence: [FINDINGS_OnePlus7.md](FINDINGS_OnePlus7.md).

## 3. What the module does

| Mechanism | Where | Effect |
|---|---|---|
| Pin `hifi_playback` to one static profile (PCM 32-bit, chosen rate, stereo) | policy XML overlay | USB music thread runs at the chosen rate instead of the DAC maximum |
| Remove `deep_buffer` from the `USB Device Out` / `USB Headset Out` routes | policy XML overlay | media that asks for deep-buffer no longer lands on the stock 48 kHz / 16-bit thread |
| Auto-follow (`bpfollow`) | root daemon | polls AudioFlinger, and when the playing track's rate differs, rewrites the overlay and restarts `audioserver` |
| Status/verification tools | `system/bin/*` | show mixer rate, source rate, bit depth, kbps, gain, enabled effects |
| Boot guard | `post-fs-data.sh`, `service.sh` | disables the overlay after 2 consecutive boots where audio never came up |

The overlay is **systemless**: Magisk mounts patched copies of `/vendor/etc/audio_policy_configuration*.xml`; the real files are never modified. Pristine copies are kept in `orig/` inside the module directory.

## 4. Version history (what each step taught us)

| Ver | Change | Outcome |
|---|---|---|
| 0.1 | Rewrite `samplingRates` of a *static* USB mix port; `bpcheck`, `bprate` | Refused to install on the reference device: it has no static USB rates |
| 0.2 | Auto-follow daemon; parser for the AudioFlinger track table | Parser was written from guesses |
| 0.3 | Verbose installer, diagnostic mode (no abort), `bpdiag` | Produced the first real dumps |
| 0.4 | Parser tweak for the Android 16 table, richer `bpdiag` | Showed USB audio rides the **primary** HAL, not a separate USB port |
| 0.5 | Pin `hifi_playback`; `bpoffload`; USB thread info | **Worked on the device**: a 44.1 kHz / 32-bit thread appeared |
| 0.6 | Remove `deep_buffer` from USB routes (media was on a 48k/16-bit deep-buffer thread) | Not confirmed on device |
| 0.7 | Single-dump probe loop, bit depth + kbps in status, optional notification | Update exposed an installer bug (below) |
| 0.8 | Installer reads **pristine** policy (fix), 2-strike boot guard, `bpdump`, parser anchored on "Tracks of which" | On device, overlay still absent in the live policy (cause unresolved) |
| 0.9 | Parser rewritten against a real dump (tests added), `bpverify`, installer log, volume/effects reporting | Not yet field-tested |
| 0.9.1 | `bpreport`, docs/CI for early adopters | Not yet field-tested |

**Installer bug found in 0.7 (fixed in 0.8):** when updating the module while the old overlay was mounted, the installer read the *already-patched* live file as "the original", found nothing to change, and shipped a module without an overlay.

## 5. Open problems

Ordered by priority. None is solved.

1. **Overlay not applied (v0.8 on reference device).** The `dumpsys media.audio_policy` output showed `hifi_playback` still dynamic and `deep_buffer` still routed to USB. The same mechanism worked in v0.5. Candidate causes, none confirmed: installer produced no overlay (diagnostic mode / aborted update), Magisk did not mount the file, another module shadows the same file, boot guard moved the overlay aside. **First action for the next maintainer:** install v0.9, reboot, run `su -c bpverify` and read [TROUBLESHOOTING.md](TROUBLESHOOTING.md).
2. **Digital attenuation.** The captured Apple Music track had **-21 dB** applied (`PortVol dB` / `G db`). Any non-zero gain means the data is not bit-exact. Media volume must be at maximum. Whether USB absolute-volume or a hardware-volume path can avoid this on Android 16 was not investigated.
3. **Enabled effect.** `Volume listener for Music` was *Enabled; Active* on the music session. Equalizer, Dynamic Bass Boost, Virtualizer and Preset Reverb (LineageOS AudioFX) were attached but *Disabled*. A patch to remove the volume listener from the effects config is planned but not written because the real `audio_effects.xml` has not been inspected (`bpverify` prints its `volume_listener` lines).
4. **Unknown DAC-side rate under USB offload.** `vendor.audio.feature.usb_offload.enable` was `true` and `/proc/asound/card0/pcm0p/sub0/hw_params` stayed `closed` during playback. That suggests the Qualcomm ADSP offload path drives the USB endpoint, so ALSA cannot confirm the DAC rate. `bpoffload off` (disables offload at next boot) is an **unverified experiment**; whether it makes the host driver visible was not tested.
5. **Spotify has not been tested on the device at all.** All captured playback was Apple Music.
6. **Switch lag.** Auto-follow needs about a second to detect, then a full `audioserver` restart (seconds), and apps must reconnect. The first moments of a track that changes rate play at the old rate. Pre-opening one output per rate was considered; whether the policy would pick the matching one was not verified, so it was not built.
7. **Rates the DAC lacks.** The reference DAC lists 44.1/48/96/192/384 kHz only, so 88.2 and 176.4 kHz tracks are always resampled.
8. **Float source.** Apple Music delivered `PCM_FLOAT`. The module cannot show whether the app decoded or processed it before Android.
9. **Untested features.** The status notification (`cmd notification post`) and `bpoffload` were never run on a device.
10. **One device, one ROM, one DAC.** See [COMPATIBILITY.md](COMPATIBILITY.md).

## 6. Requested but not started

- A **simple UI / home- and lock-screen widget** showing rate, bit depth and bit-perfect state, with controls, instead of a terminal. Not designed. A reasonable first step is an app that reads `/data/adb/usb_dac_bitperfect/status` (written by `bpfollow`) through a root shell and calls the `bprate` commands; this is an idea, not researched.

## 7. How to work on it

```sh
sh tests/run.sh            # 28 offline tests (policy patching, dump parsing, rate picking)
sh scripts/build.sh        # -> dist/BitPerfect-DAC-<version>.zip (+ .sha256)
```

- Scripts target Android's `mksh`/toybox and Magisk's busybox `awk`. Keep them POSIX; no bashisms.
- Everything that parses `dumpsys` is in `module/common.sh` and covered by fixtures in `tests/fixtures/`. **Add a fixture for every new device/ROM dump.** The Android 16 track-table layout (blank `Type` column, `pid/  uid` split over two tokens) already broke one parser.
- Never ship an overlay without the sanity checks in `patch_ok`.

## 8. Safety and recovery

- Overlay files live only under the module directory. To remove: Magisk app → remove module → reboot; or from a root shell `touch /data/adb/modules/usb_dac_bitperfect/remove`; or from recovery delete `/data/adb/modules/usb_dac_bitperfect`.
- Boot guard: after two consecutive boots in which `audioserver`/AudioFlinger did not come up within ~10 s of boot completion, the module renames its `system/` folder, creates `disable`, and rewrites its description. Reinstall to re-enable.
- `bprate auto off` stops the daemon; it also stops by itself after more than 6 switches in 2 minutes.
- State lives in `/data/adb/usb_dac_bitperfect/` and is removed by `uninstall.sh`.

## 9. Release checklist (do not skip)

1. `sh tests/run.sh` passes.
2. On a device: fresh install **and** update-over-previous install; reboot; `bpverify` shows the live policy patched.
3. Play a 44.1 kHz and a 96 kHz track in each app; `bpstatus` shows mixer = source rate, gain 0 dB, no enabled effects.
4. Uninstall leaves `/vendor/etc/audio_policy_configuration.xml` byte-identical to stock.
5. Update [COMPATIBILITY.md](COMPATIBILITY.md) and [CHANGELOG.md](../CHANGELOG.md); attach sanitized dumps.
