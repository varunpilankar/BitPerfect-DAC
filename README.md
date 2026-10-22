# BitPerfect DAC

**Your music. Your DAC. No unnecessary resampling.**

BitPerfect DAC is an experimental Magisk module project focused on preserving native audio sample rates when playing music through external USB DACs on Android.

The initial goal is to investigate and address unnecessary audio resampling in the Android audio pipeline, particularly when listening to Apple Music and Spotify through a USB DAC.

> **Status: Early development.** The audio modifications are not yet validated. Bit-perfect playback, app compatibility, and device compatibility have not been established.

## Overview

Android's audio framework may mix audio streams and convert them to a common output format or sample rate, depending on the device, audio HAL, application, and output path.

For listeners using external USB DACs, this can mean that audio does not necessarily reach the DAC in its original digital format.

BitPerfect DAC aims to investigate ways to reduce or prevent unnecessary resampling while maintaining stable audio playback.

### Project goals

- Investigate Android audio resampling behavior with external USB DACs.
- Explore solutions compatible with Magisk and rooted Android devices.
- Focus initially on Apple Music and Spotify playback.
- Preserve the source sample rate where the complete audio path permits it.
- Document device compatibility and reproducible test results.
- Avoid unnecessary system modifications and provide a reliable uninstall path.

### What this project does not promise

- Bit-perfect output on every Android device.
- Guaranteed Hi-Res or lossless output from every streaming service or subscription.
- Bypassing application, DRM, audio HAL, or hardware limitations.
- Improved sound quality simply from changing a sample rate.
- Compatibility with every Android version, ROM, root solution, or USB DAC.

## Current status

| Component | Status |
| --- | --- |
| Repository and documentation | In progress |
| Android audio-path research | Planned |
| Resampling investigation | Planned |
| Magisk module implementation | Not validated |
| Apple Music compatibility | Untested |
| Spotify compatibility | Untested |
| USB DAC compatibility matrix | Pending |
| Bit-perfect output verification | Pending |

No production-ready release is available until the implementation and its compatibility have been tested.

## Intended compatibility

The initial investigation will focus on:

- Rooted Android devices using Magisk.
- External USB DACs connected through Android USB audio.
- Apple Music and Spotify playback.
- Lossless and high-resolution source material where supported by the service, subscription, track, and device.

Actual compatibility will depend on the Android version, device audio implementation, application behavior, DAC capabilities, and the method used to route audio.

See docs/COMPATIBILITY.md for the compatibility matrix.

## Installation

**Do not install this repository as a functional audio modification yet.** The initial source tree is a development baseline, not a tested release.

Once a tested release is available, installation instructions will be published here with the release ZIP, supported configurations, prerequisites, and recovery instructions.

Do not flash experimental builds on a device you cannot safely recover.

## Verifying bit-perfect playback

A sample-rate indicator alone does not prove bit-perfect output.

Testing should distinguish between:

1. The source track's sample rate and bit depth.
2. The format requested by the application.
3. The format used by Android's audio pipeline.
4. The USB audio format negotiated with the DAC.
5. Whether the audio samples themselves remain unaltered.

Where possible, verification should use reproducible test signals, USB audio diagnostics, and independent measurement rather than relying only on a DAC display.

See docs/TESTING.md.

## Roadmap

### Phase 1 — Research and baseline

- [ ] Document the Android USB audio pipeline.
- [ ] Establish a baseline on a rooted test device.
- [ ] Record the behavior of Apple Music and Spotify without modifications.
- [ ] Identify the point at which resampling occurs.
- [ ] Document safe rollback and recovery procedures.

### Phase 2 — Proof of concept

- [ ] Identify a technically justified intervention.
- [ ] Implement the smallest reversible change.
- [ ] Confirm that installation and removal work correctly.
- [ ] Check for boot loops, audio failures, and unexpected system changes.
- [ ] Compare output behavior against the baseline.

### Phase 3 — Compatibility and validation

- [ ] Test multiple source sample rates.
- [ ] Verify USB DAC output format and sample integrity.
- [ ] Test Apple Music and Spotify separately.
- [ ] Document Android versions, ROMs, and device-specific behavior.
- [ ] Publish test evidence and known limitations.

### Phase 4 — Release

- [ ] Finalize the module installation and uninstallation flow.
- [ ] Add release packaging and versioning.
- [ ] Publish a tested release ZIP and checksums.
- [ ] Maintain compatibility notes and a changelog.

## Contributing

Contributions are welcome, especially:

- Android audio architecture research.
- Reproducible resampling tests.
- USB DAC compatibility reports.
- Device-specific diagnostic information.
- Code reviews and improvements to installation safety.

Please read CONTRIBUTING.md before submitting changes.

## Reporting issues

Use GitHub Issues to report reproducible bugs, suggest features, or share compatibility results.

Include your Android version, device model, ROM, root solution, DAC model, streaming application version, source track format, and relevant diagnostic logs.

Do not publish personal information or sensitive device logs.

For suspected security vulnerabilities, follow SECURITY.md.

## Disclaimer

BitPerfect DAC is an independent community project. It is not affiliated with, endorsed by, or sponsored by Apple, Spotify, Google, or the Magisk project.

Apple Music and Spotify are trademarks of their respective owners.

Root modifications can affect system stability, audio behavior, and device security. You are responsible for backing up your device and understanding the risks before installing experimental software.

## License

This project is intended to be distributed under the GNU General Public License v3.0 (GPL-3.0). See LICENSE for the full license text.
