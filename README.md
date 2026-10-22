# BitPerfect DAC

**Your music. Your DAC. No unnecessary resampling.**

[![CI](https://github.com/varunpilankar/BitPerfect-DAC/actions/workflows/ci.yml/badge.svg)](https://github.com/varunpilankar/BitPerfect-DAC/actions/workflows/ci.yml)
![status: experimental](https://img.shields.io/badge/status-experimental-orange)
![license: GPL-3.0](https://img.shields.io/badge/license-GPL--3.0-blue)

BitPerfect DAC is an experimental Magisk module for rooted Android devices. It stops Android from resampling music to an unnecessary fixed rate when you play through an external USB DAC, with a focus on **Apple Music** and **Spotify**, and gives you terminal tools to **see what Android is really doing**.

> **Status: early testing (v0.9.x).** Built from diagnostics of one device. The module has **not** yet been confirmed to give rate-matched, unity-gain output end to end, and **Spotify has not been tested at all.** It is for early adopters who can recover a device. Read [Before you install](#before-you-install).

## Why this exists

On the reference device (OnePlus 7, LineageOS 23.2, Android 16) a 96 kHz Apple Music track was played through a USB DAC like this:

```
Mixer 384 kHz / 32-bit container (24576 kbps) | Source 96 kHz / 32-bit (6144 kbps) | gain -21 dB |
RESAMPLED 96 kHz->384 kHz, VOLUME -21 dB: set media volume to MAX, float source
```

Android had opened the USB output at the DAC's **maximum** rate (384 kHz) and resampled the track to it, and a digital volume of −21 dB was applied. That is not bit-perfect. The module changes where the music is routed and at which rate that output runs. Details and evidence: [docs/FINDINGS_OnePlus7.md](docs/FINDINGS_OnePlus7.md).

## What it does

- **Pins the USB music output** (`hifi_playback`) to one fixed rate (default 44.1 kHz, 32-bit container) instead of the DAC's maximum.
- **Keeps media off the stock 48 kHz / 16-bit deep-buffer output** when a USB DAC is the target.
- **Optionally follows the track:** a small daemon notices the playing track's sample rate and switches the output rate to match (this restarts the audio server, so expect a short interruption).
- **Shows the truth in a terminal:** mixer rate, source rate and format, bit depth, kbps, digital gain, enabled effects, and a `rate-matched` / `RESAMPLED` verdict.
- **Systemless and reversible:** edits are a Magisk overlay; your real `/vendor` files are never modified. A boot guard disables the overlay if audio fails to start twice.

### What it does not do

- Guarantee bit-perfect output, on this or any other device.
- Make Apple Music or Spotify request Android's own bit-perfect mode.
- See inside the apps (their own DSP, volume or resampling), or prove bit-exactness for DRM-protected streams.
- Work on devices whose audio policy does not have this layout. The installer then installs in *diagnostic mode* and changes nothing.
- Guarantee Hi-Res/lossless delivery; that depends on the service, subscription, track and DAC.

## Current status

| Component | Status |
| --- | --- |
| Repository and documentation | In place ([docs/](docs/)) |
| Android audio-path research | Documented for one device ([architecture](docs/ARCHITECTURE.md), [findings](docs/FINDINGS_OnePlus7.md)) |
| Resampling investigation | Baseline confirmed on one device (384 kHz mixer, resampling) |
| Magisk module implementation | Experimental v0.9.x. The pin was seen to take effect once; a later session showed the overlay missing (cause open) |
| Apple Music compatibility | One track captured; not confirmed bit-perfect |
| Spotify compatibility | **Untested** |
| USB DAC compatibility matrix | 1 device / 1 DAC ([COMPATIBILITY](docs/COMPATIBILITY.md)) |
| Bit-perfect output verification | Tools exist; bit-exactness cannot be proven on-device for streaming apps ([TESTING](docs/TESTING.md)) |

No production-ready release exists. Pre-releases are published under [Releases](../../releases) for testers.

## Before you install

- You need a **rooted device with Magisk** and an **external USB DAC**.
- Developed and observed on **Android 16 / LineageOS 23.2 (Qualcomm)**. Other versions, ROMs and chipsets are untested; the module only acts if it finds the expected audio-policy layout.
- **Back up your data and know how to recover** (Magisk safe mode, recovery, or deleting the module folder from a root shell). See [docs/INSTALL.md](docs/INSTALL.md).
- Remove other modules that edit audio policy or effects (e.g. HiFi SRC Bypass, NLSound) before testing; they edit the same files.
- Set **media volume to maximum**, and turn off AudioFX / EQ / loudness / crossfade / volume normalisation in your music app.

## Quick start

1. Download `BitPerfect-DAC-<version>.zip` from [Releases](../../releases) (verify the `.sha256`), or build it: `sh scripts/build.sh`.
2. Magisk → **Modules → Install from storage** → select the ZIP → read the installer lines → **reboot**.
3. Plug in the DAC and **play a track**.
4. In a root shell (Termux: `su`) run:

   ```sh
   bpstatus        # one-line truth: mixer vs source rate, bit depth, gain
   bpverify        # is the overlay actually live? (share this when reporting)
   ```

What you want to see (illustrative):

```
Mixer 44.1 kHz / 32-bit container (2822 kbps) | Source 44.1 kHz / 16-bit (1411 kbps) | gain 0 dB | rate-matched
```

If you see `RESAMPLED`, `VOLUME -N dB`, `ENABLED EFFECTS` or the overlay is not live, follow [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md).

## Commands

| Command | Purpose |
| --- | --- |
| `bpstatus` / `bpstatus -w` | Live status line (and enabled effects) |
| `bpcheck` | Status plus DAC capabilities, ALSA view, USB threads and track table |
| `bprate [status]` · `bprate <Hz>` | Show or set the mixer rate (44100 … 384000; checks the DAC lists it) |
| `bprate auto on\|off` | Follow-the-track daemon |
| `bprate deepbuffer keep\|trim` | Keep or remove the deep-buffer output on USB routes |
| `bpverify` | Why the overlay is or is not active |
| `bpreport` | **Sanitized tester report** → `/sdcard/Download/bitperfect-report.txt` (run while playing) |
| `bpdump` / `bpdiag` | Full dumps / environment diagnostics for bug reports |
| `bpoffload on\|off` | Experiment: disable Qualcomm USB offload at next boot |

Full reference: [module/README.md](module/README.md).

## Verifying bit-perfect playback

A sample-rate indicator alone does not prove bit-perfect output. Testing should distinguish between:

1. The source track's sample rate and bit depth.
2. The format requested by the application.
3. The format used by Android's audio pipeline.
4. The USB audio format negotiated with the DAC.
5. Whether the audio samples themselves remain unaltered.

`bpstatus` covers items 1–3 on the Android side. Under Qualcomm USB offload, item 4 may not be observable from Android, and item 5 cannot be proven for DRM streams without external capture. See [docs/TESTING.md](docs/TESTING.md).

## Help us test

This project needs reproducible results from more devices, DACs and apps. The 15-minute procedure is in **[docs/TESTER_GUIDE.md](docs/TESTER_GUIDE.md)**. In short: run `bpstatus` before and after installing, play a 44.1 kHz and a 96 kHz track in **Apple Music and Spotify**, then submit `bpreport` through a [compatibility report](../../issues/new?template=compatibility_report.md).

## How it works (short)

Android mixes every app's audio on an output thread with **one fixed rate and format**; a track at any other rate is resampled. The rate comes from the audio policy. On the reference device the USB DAC's music output was a vendor mix port with *no* profile, which the policy opens at the DAC maximum. The module replaces it with one fixed profile and re-routes deep-buffer media. Full explanation: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Known issues

- On the reference device a later (v0.8) session showed the overlay **not applied**; cause unresolved. Run `bpverify`.
- Digital volume below maximum and enabled effects (e.g. "Volume listener") break bit-exactness.
- Rate switching in auto-follow takes seconds (audio-server restart); the first moments of a track may play at the old rate.
- DACs that lack 88.2/176.4 kHz still force resampling for those tracks.
- The DAC-side rate cannot be confirmed from Android while USB offload is active.

Full list and priorities: [docs/HANDOVER.md](docs/HANDOVER.md#5-open-problems).

## Documentation

| Doc | For |
| --- | --- |
| [INSTALL](docs/INSTALL.md) | Install, update, uninstall, recovery |
| [TESTER_GUIDE](docs/TESTER_GUIDE.md) | Step-by-step test and reporting |
| [TESTING](docs/TESTING.md) | What each check proves and does not prove |
| [TROUBLESHOOTING](docs/TROUBLESHOOTING.md) | Reading `bpverify` / `bpstatus` |
| [FAQ](docs/FAQ.md) | Common questions, glossary |
| [ARCHITECTURE](docs/ARCHITECTURE.md) | How it works |
| [FINDINGS_OnePlus7](docs/FINDINGS_OnePlus7.md) | Evidence from the reference device |
| [COMPATIBILITY](docs/COMPATIBILITY.md) | Tested configurations |
| [DECISIONS](docs/DECISIONS.md) | Design choices, rejected options, prior art |
| [HANDOVER](docs/HANDOVER.md) | State of the project for maintainers |
| [CHANGELOG](CHANGELOG.md) | Version history |

## Roadmap

### Phase 1 — Research and baseline

- [x] Document the Android USB audio pipeline (one device).
- [x] Establish a baseline on a rooted test device.
- [x] Record the behavior of Apple Music without modifications (one track).
- [ ] Record the behavior of Spotify without modifications.
- [x] Identify the point at which resampling occurs (384 kHz `hifi_playback` mixer).
- [x] Document safe rollback and recovery procedures.

### Phase 2 — Proof of concept

- [x] Identify a technically justified intervention (policy overlay).
- [x] Implement the smallest reversible change.
- [ ] Confirm that installation, update and removal work correctly on devices.
- [ ] Check for boot loops, audio failures, and unexpected system changes.
- [ ] Compare output behavior against the baseline with matching rate, 0 dB gain and no effects.

### Phase 3 — Compatibility and validation

- [ ] Test multiple source sample rates.
- [ ] Verify USB DAC output format and sample integrity.
- [ ] Test Apple Music and Spotify separately.
- [ ] Document Android versions, ROMs, and device-specific behavior.
- [ ] Publish test evidence and known limitations.
- [ ] Remove the enabled "volume listener" effect safely; investigate USB hardware volume.
- [ ] Reduce rate-switch lag; evaluate USB offload on/off.

### Phase 4 — Release

- [ ] Finalize the module installation and uninstallation flow.
- [x] Add release packaging and versioning (`scripts/build.sh`, CI).
- [ ] Publish a tested release ZIP and checksums (pre-releases only so far).
- [ ] Companion app / widget for monitoring and control (requested; not started).
- [ ] Maintain compatibility notes and a changelog.

## Contributing

Contributions are welcome, especially:

- Android audio architecture research.
- Reproducible resampling tests.
- USB DAC compatibility reports.
- Device-specific diagnostic information.
- Code reviews and improvements to installation safety.

Please read [CONTRIBUTING.md](CONTRIBUTING.md) before submitting changes. Run `sh tests/run.sh` (28 offline checks) first.

## Reporting issues

Use [GitHub Issues](../../issues) to report reproducible bugs, suggest features, or share compatibility results.

Include your Android version, device model, ROM, root solution, DAC model, streaming application version, source track format, and relevant diagnostic logs (`bpreport` produces a sanitized one).

Do not publish personal information or sensitive device logs. For suspected security vulnerabilities, follow [SECURITY.md](SECURITY.md).

## Credits and prior art

Related community projects informed the investigation (ideas only, no code copied): Audio Samplerate Changer, hifi-maximizer-mod, usb-samplerate-unlocker, magisk-usb-fast-44100, audio-misc-settings, and the AOSP documentation on [preferred mixer attributes for USB](https://source.android.com/docs/core/audio/preferred-mixer-attr). See [docs/DECISIONS.md](docs/DECISIONS.md).

## Disclaimer

BitPerfect DAC is an independent community project. It is not affiliated with, endorsed by, or sponsored by Apple, Spotify, Google, or the Magisk project.

Apple Music and Spotify are trademarks of their respective owners.

Root modifications can affect system stability, audio behavior, and device security. You are responsible for backing up your device and understanding the risks before installing experimental software.

## License

This project is distributed under the GNU General Public License v3.0 (GPL-3.0). See [LICENSE](LICENSE) for the full license text.
