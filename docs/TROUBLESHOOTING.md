# Troubleshooting

Run `su -c bpverify` first (and `su -c bpreport` to produce a shareable, sanitized report). How to read it:

| Symptom in `bpverify` | Meaning | Action |
|---|---|---|
| `pinned hifi_playback lines: 0` and `overlay files` empty | Installer built no overlay (diagnostic mode) | Read `installer log`; usually "nothing to rewrite" (this ROM names ports differently) or "already patched, no pristine copy" → remove module, reboot, reinstall |
| `pinned hifi_playback lines: 0` but overlay files present | Magisk did not mount them, or another module shadows the file | Check `other modules`; disable modules that edit audio policy (HiFi SRC Bypass, NLSound, others); check `mounts touching vendor/etc` |
| `disable` / `system.disabled` present | Boot guard fired (audio failed twice) | Reinstall; check `boot.log` |
| pinned lines = 1 but `bpstatus` mixer still 384 kHz | Audio server did not reload, or music uses another output | reboot; run `bpdump` while playing and look at which `Output thread` holds the active track |
| `playing, but source track not parsed` | Track-table layout differs on your ROM | Run `bpdump`, open an issue with the sanitized dump; add a fixture |
| `VOLUME -N dB` | Digital attenuation active | Media volume to max, control level on the DAC/amp |
| `ENABLED EFFECTS` | An effect alters the signal | Turn off AudioFX/EQ; volume-listener removal not yet implemented |
| Audio slow/low-pitched after install | A fixed-rate pin conflicts with a FAST path (reported for 44.1 kHz USB on another Android 16 device: github.com/jgroman/magisk-usb-fast-44100) | `su -c 'bprate 48000'` or remove module |
| No audio at all | Policy edit rejected | Reboot twice (boot guard), or remove via recovery (see HANDOVER §8) |

## Do not combine
HiFi SRC Bypass, NLSound and similar modules edit the same policy/effects files. Test this module alone first.

## Sanitizing logs
`bpdump` includes package names, pids and uids. Remove anything you do not want public before posting.
