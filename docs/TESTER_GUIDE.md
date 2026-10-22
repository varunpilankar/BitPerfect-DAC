# Tester guide (about 15 minutes)

Thank you for testing. The goal is **reproducible evidence**, not just "it sounds better". Please read [INSTALL.md](INSTALL.md) first.

## You need
Rooted Android + Magisk, a USB DAC, Termux (or any root shell), and Apple Music and/or Spotify with a lossless/hi-res track at **44.1 kHz** and one at **48 kHz or higher (96 kHz ideal)**. Note each track's advertised format.

## Prepare
- Media volume **maximum**; control loudness on the DAC/amp.
- App: disable EQ, loudness, volume normalisation, crossfade. Android: disable LineageOS AudioFX.
- Remove other audio-policy modules (HiFi SRC Bypass, NLSound, …).

## Steps

| # | Do | Record | Pass criterion |
|---|---|---|---|
| T1 | **Before installing:** play the 96 kHz track and run the *baseline command* below | USB thread rate and format | Baseline noted |
| T2 | Install ZIP, reboot, replug DAC | Installer lines | Says *patched*, not *DIAGNOSTIC* |
| T3 | `su -c bpverify` | `pinned hifi_playback lines`, `deep_buffer in USB routes` | pinned ≥ 1; deep_buffer not in USB routes |
| T4 | Play the **44.1 kHz** track; `su -c bpstatus` | the line | `rate-matched`, `gain 0 dB`, no `RESAMPLED`/`VOLUME` |
| T5 | Play the **96 kHz** track | the line | With auto-follow on: switches to 96 kHz (a short dropout is expected), then `rate-matched` |
| T6 | `su -c 'tail -5 /data/adb/usb_dac_bitperfect/follow.log'` | switch timings | "detect X ms, restart Y ms" recorded |
| T7 | Repeat T4–T5 in the **other** streaming app | the lines | Same criteria |
| T8 | `su -c bpstatus` second line | enabled effects | none listed |
| T9 | `su -c bpreport` (while playing) | file `/sdcard/Download/bitperfect-report.txt` | produced |
| T10 | Uninstall, reboot | `bpstatus` no longer present | Audio works as before |

Baseline command (works without the module):

```sh
su -c "dumpsys media.audio_flinger" | grep -E "^Output thread|Sample rate:|HAL format:|Output devices:"
```

If the DAC does not list the track's rate (some lack 88.2/176.4 kHz) `RESAMPLED` is expected; note it.

## Interpreting results
- `rate-matched` + `gain 0 dB` + no effects = Android is not altering the stream (as far as it can show). It is **not** proof of bit-exactness; see [TESTING.md](TESTING.md).
- `playing, but source track not parsed` = your ROM prints the dump differently; this is useful, report it.
- Under USB offload `/proc/asound/card*/pcm0p/sub0/hw_params` stays `closed`; that is expected on Qualcomm devices and not a failure.

## Report
Open a **Compatibility report** issue and paste/attach the `bpreport` file after reading it. It removes pid/uid pairs and kernel pointers but keeps the device model, DAC model and module names. Please also state anything unusual (audio glitches, silence, boot problems).
