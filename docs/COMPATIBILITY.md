# Compatibility matrix

Only results backed by captured diagnostic output are listed. "Untested" means untested, not "unsupported".

| Device | ROM / Android | Root | DAC | App | Result |
|---|---|---|---|---|---|
| OnePlus 7 (`guacamoleb`) | LineageOS 23.2 (2026-09-20) / Android 16 | Magisk | CrinEar Protocol Micro | Apple Music 24/96 | Baseline confirmed: music on a 384 kHz/32-bit mixer (resampled). Pin mechanism (v0.5) observed to create a 44.1 kHz/32-bit thread. **End-to-end bit-perfect: not achieved/confirmed.** Overlay missing in the v0.8 session. |
| same | same | Magisk | same | Spotify | Untested |
| Any other device | – | – | – | – | Untested |

## Legend
- **Confirmed rate-matched:** `bpstatus` showed `rate-matched`, `gain 0 dB`, no enabled effects while playing.
- **Partial:** pin observed, but one of the above missing.
- **Baseline only:** stock behaviour captured, module not (successfully) applied.

## What is device-specific
- The mix port name `hifi_playback` and USB-on-primary-HAL routing are Qualcomm/OnePlus vendor choices.
- AIDL-only audio HAL devices may expose the platform bit-perfect mixer behaviour; this module does not target them.
- Devices whose USB output is a static mix port may only need the v0.1-style rate rewrite (kept in `patch_policy`).

## Submit a result
Follow [TESTER_GUIDE.md](TESTER_GUIDE.md) and open a *Compatibility report* issue with the `bpreport` file (taken **while a track plays**).
