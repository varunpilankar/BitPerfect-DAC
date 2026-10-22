# Testing and verification

A displayed sample rate does not prove bit-perfect output. What each layer can and cannot prove:

| Check | Command | Proves | Does not prove |
|---|---|---|---|
| Policy overlay live | `su -c bpverify` | `hifi_playback` pinned, `deep_buffer` off USB routes | that audio uses it |
| Mixer rate / container | `su -c bpstatus` | AudioFlinger USB thread rate and HAL format | the DAC's rate under USB offload |
| Source rate / format / gain | `su -c bpstatus` | what the app handed to Android; gain (`G db`, `PortVol dB`) | what the app did before |
| Effects | `bpstatus` (2nd line) | effects *enabled* on any output | effects inside the app |
| Host ALSA view | `cat /proc/asound/card*/pcm0p/sub0/hw_params` | rate/format on the USB endpoint **if the host driver carries the stream** | anything when offload is active (`closed`) |
| Bit-exactness | external capture (loopback/digital analyzer with a known test file) | sample integrity | – |

For streaming apps (DRM) a known test file cannot be played, so **bit-exactness cannot be proven on-device**; the module can only prove the Android side is rate-matched, unity-gain and effect-free.

## Procedure
1. Media volume to **maximum**; disable LineageOS AudioFX and any app EQ/normalisation/crossfade.
2. `su -c bpverify` – confirm patched policy.
3. Play a 44.1 kHz track, then a 96 kHz track; run `su -c bpstatus` during each. Expected: `rate-matched`, `gain 0 dB`, no `RESAMPLED`/`VOLUME` flag, no enabled effects.
4. Save evidence with `su -c bpdump` and `su -c bpverify`.

## Automated tests
`sh tests/run.sh` – 28 checks over fixtures in `tests/fixtures/`. Fixtures are modelled on structures observed on the reference device. Add a fixture for each new device.
