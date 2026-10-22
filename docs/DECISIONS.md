# Design decisions and rejected alternatives

| Decision | Reason | Alternatives not taken |
|---|---|---|
| Edit audio policy via Magisk overlay | systemless, reversible, no framework patching | Patching `libaudioflinger`/HAL binaries (fragile, ROM-specific); other modules reportedly patch vendor libraries – not reviewed in depth |
| Pin `hifi_playback` to one static profile | the observed source of the 384 kHz thread | Adding multiple pinned ports (one per rate) so no restart is needed: unverified whether Android's output selection would pick the matching one |
| Remove `deep_buffer` from USB routes | media landed on the 48 kHz / 16-bit thread | Pin `deep_buffer` itself (shared with speaker/headset; side effects) |
| Restart `audioserver` to change rate | the policy is parsed at start | No lighter reload mechanism was found |
| Poll `dumpsys media.audio_flinger` | only source of per-track rate found | `dumpsys audio`/policy dumps do not list track rates; logcat events not found reliable |
| Pristine copies kept in the module | avoid reading our own overlay as input (v0.7 bug) | Reading Magisk mirrors only (path varies across Magisk variants) |
| Abort install rather than ship an empty overlay on update | protects a working install | silent diagnostic mode (v0.3–0.7 behaviour) |
| Boot guard: 2 strikes | one quick reboot must not disable the module | single-strike guard (v0.1–0.7) |
| 32-bit container, stereo only | USB profile exposes `PCM_32_BIT`; simplest lossless container | 24-bit packed; multichannel (`0x80000003` appears in the DAC profile; not handled) |
| Offline POSIX test gate in CI | module scripts run on device root shells where mistakes risk audio/boot issues; fixtures catch regressions before packaging | manual device-only testing |
| Publish tagged builds as GitHub pre-releases | end-to-end bit-perfect output is not yet confirmed on-device; avoids implying production readiness | marking unverified tags as stable releases |

See [PLANS.md](PLANS.md) for the milestone roadmap and planned investigations for open items.

## Prior art reviewed (ideas only; no code copied)
- Magisk-Modules-Alt-Repo/audio-samplerate-changer – changes mixer sample rates system-wide (max-rate approach).
- yzyhk904/hifi-maximizer-mod – reduces jitter on USB/Bluetooth outputs.
- Magisk-Modules-Alt-Repo/usb-samplerate-unlocker – unlocks higher USB rates.
- jgroman/magisk-usb-fast-44100 – fixes slow-motion audio through a 44.1 kHz USB device on Android 16 for low-latency apps.
- cosminnionutt/audio-misc-settings – misc. audio properties (volume steps, resampler quality, effects framework).
- AOSP: [Preferred mixer attributes on USB devices](https://source.android.com/docs/core/audio/preferred-mixer-attr).

Only repository descriptions/READMEs were read, not their source. Credit and licences remain with their authors.
