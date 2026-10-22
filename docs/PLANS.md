# Project plans and milestone criteria

This document tracks the concrete execution plan, technical investigation tracks, and release gates for `varunpilankar/BitPerfect-DAC`. Read it alongside [HANDOVER.md](HANDOVER.md), [DECISIONS.md](DECISIONS.md), and [FINDINGS_OnePlus7.md](FINDINGS_OnePlus7.md).

> **Current state (v0.9.1):** Experimental pre-release. Offline policy patching and dump-parsing logic are covered by `tests/run.sh`, but end-to-end rate-matched, unity-gain USB DAC playback has **not** yet been confirmed on-device.

## 1. Milestone plan

| Milestone | Scope | Exit criteria (done when) | Status |
|---|---|---|---|
| **M1 — Repository, CI & baseline docs** | GitHub repo setup, CI test/build workflow, pre-release workflow, issue/PR templates, offline test suite (`tests/run.sh`), early-adopter docs | `sh tests/run.sh` and `sh scripts/build.sh` pass locally and in GitHub Actions; docs accurately distinguish verified findings from unverified assumptions | Complete (v0.9.1) |
| **M2 — Overlay & baseline verification (v0.9.x)** | Confirm v0.9.1 overlay mounting on the reference device (OnePlus 7, LineageOS 23.2, Android 16) and capture a Spotify baseline | `su -c bpverify` shows `pinned hifi_playback lines: 1` and `deep_buffer` absent from USB routes after both fresh install and update-over-previous; sanitized `bpreport` attached for Apple Music and Spotify at 44.1 kHz and 96 kHz | Planned / awaiting device capture |
| **M3 — Signal-path hygiene (v0.10.x)** | Address active effects (`Volume listener for Music`), digital attenuation guidance, and USB offload observability | Inspected `/vendor/etc/audio_effects.xml` from reference device; safe overlay or documented disablement so `bpstatus` reports no enabled effects; `bpoffload off` tested and documented | Planned |
| **M4 — Validated release (v1.0.0)** | First non-prerelease build backed by captured device evidence | Release checklist in [HANDOVER.md](HANDOVER.md#9-release-checklist-do-not-skip) satisfied across at least one verified device/DAC pair for both 44.1 kHz and 96 kHz playback | Not started |

## 2. Technical investigation plans

Each track corresponds to an open problem in [HANDOVER.md §5](HANDOVER.md#5-open-problems) and the unverified items in [FINDINGS_OnePlus7.md](FINDINGS_OnePlus7.md).

### Track P1 — Live overlay verification on the reference device
- **Problem:** In the v0.8 session on OnePlus 7 (`guacamoleb`), `dumpsys media.audio_policy` still showed `Config source: /vendor/etc/audio_policy_configuration.xml` with `hifi_playback` dynamic and `deep_buffer` routed to USB ([FINDINGS_OnePlus7.md §F8](FINDINGS_OnePlus7.md)).
- **Plan:**
  1. Flash v0.9.1 cleanly (after removing any older module version and rebooting).
  2. Run `su -c bpverify` and inspect `install.log`, `boot.log`, SELinux context (`u:object_r:vendor_configs_file:s0`), and `/proc/mounts`.
  3. Test an in-place update (`v0.9.1` over `v0.9.1`) to verify pristine-copy reuse in `customize.sh`.
- **Deliverable:** Sanitized `bpverify` output recorded in [FINDINGS_OnePlus7.md](FINDINGS_OnePlus7.md) and [COMPATIBILITY.md](COMPATIBILITY.md).

### Track P2 — Spotify baseline and rate-matching capture
- **Problem:** All captured evidence to date is from Apple Music; Spotify is untested ([FINDINGS_OnePlus7.md](FINDINGS_OnePlus7.md)).
- **Plan:**
  1. Capture stock AudioFlinger output (`dumpsys media.audio_flinger`) while playing a 44.1 kHz track in Spotify without the module installed.
  2. Repeat with the module active at 44.1 kHz and verify `bpstatus` output (`rate-matched`, `gain 0 dB`, track format).
  3. Add a sanitized Spotify track-table fixture to `tests/fixtures/` if its column layout differs.
- **Deliverable:** Compatibility matrix entry in [COMPATIBILITY.md](COMPATIBILITY.md) and test fixture in `tests/`.

### Track P3 — Eliminating enabled `Volume listener for Music` effect
- **Problem:** Qualcomm's `Volume listener for Music` effect stays `Enabled; Active` on the music session even when LineageOS AudioFX equalizers are disabled ([FINDINGS_OnePlus7.md §F6](FINDINGS_OnePlus7.md)).
- **Plan:**
  1. Collect the `### effects xml (volume listener lines)` section from `su -c bpverify` on the reference device.
  2. Design a minimal, reversible overlay for `audio_effects.xml` (guarded by a toggle and `patch_ok`-style sanity check) that strips or disables the `volume_listener` effect on music output sessions without breaking voice call or speaker calibration paths.
  3. Add offline fixtures and tests in `tests/run.sh`.
- **Deliverable:** Optional effects-overlay support and verification that `bpstatus` prints no `ENABLED EFFECTS` line.

### Track P4 — USB offload vs host ALSA observability
- **Problem:** With `vendor.audio.feature.usb_offload.enable=true`, `/proc/asound/card0/pcm0p/sub0/hw_params` reads `closed` during playback ([FINDINGS_OnePlus7.md §F7](FINDINGS_OnePlus7.md)), preventing kernel ALSA verification of the negotiated USB rate.
- **Plan:**
  1. Run `su -c 'bpoffload off'`, reboot, and test playback at 44.1 kHz and 96 kHz.
  2. Check whether `/proc/asound/card0/pcm0p/sub0/hw_params` reports the active rate and format (`S32_LE` / `S24_3LE`) when offload is disabled, and whether audio stability or CPU usage is affected.
  3. Restore `su -c 'bpoffload on'` and document findings.
- **Deliverable:** Evidence section in [FINDINGS_OnePlus7.md](FINDINGS_OnePlus7.md) and guidance in [TESTING.md](TESTING.md).

### Track P5 — Digital volume and unity-gain path
- **Problem:** AudioFlinger attenuates the stream digitally (`PortVol dB = -21` in [FINDINGS_OnePlus7.md §F5](FINDINGS_OnePlus7.md)) whenever Android media volume is below maximum.
- **Plan:**
  1. Confirm `PortVol dB = 0` and `G db = 0` in `bpstatus` when media volume is at maximum.
  2. Investigate whether `setDeviceAbsoluteVolumeEnabled` or USB hardware mixer controls (`tinymix` / ALSA controls on `card0`) allow hardware-side attenuation without digital scaling in AudioFlinger.
- **Deliverable:** Updated guidance in [TROUBLESHOOTING.md](TROUBLESHOOTING.md) and [DECISIONS.md](DECISIONS.md).

## 3. Repository and release workflow

- **Branching:** Changes are developed on feature or documentation branches and merged into `main` via pull requests after CI passes.
- **Continuous integration (`.github/workflows/ci.yml`):** Every push to `main`, pull request, or manual dispatch runs `sh tests/run.sh`, syntax-checks all POSIX shell scripts (`sh -n`), and builds the flashable Magisk ZIP via `sh scripts/build.sh`.
- **Pre-releases (`.github/workflows/release.yml`):** Pushing a `v*` tag runs the test suite, builds `dist/BitPerfect-DAC-<version>.zip` and its `.sha256` checksum, and publishes a GitHub Release marked `--prerelease`. Builds remain marked experimental until Milestone M4 criteria are met.
- **Issue intake (`.github/ISSUE_TEMPLATE/`):** Structured templates collect sanitized `bpverify` output for bug reports and `bpreport` output for device/DAC/app compatibility reports.
