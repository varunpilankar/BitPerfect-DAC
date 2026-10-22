# Module usage (v0.9.1, experimental)

Flash `BitPerfect-DAC-<version>.zip` in Magisk, **reboot**, then use a root shell (Termux: `su`).

| Command | Purpose |
|---|---|
| `bpstatus` / `bpstatus -w` | one-line status: mixer rate/bit depth/kbps, source rate/format, gain, rate-matched or RESAMPLED; second line lists enabled effects |
| `bpcheck` | status plus DAC capabilities, ALSA `hw_params`, AudioFlinger USB threads, track table, volume |
| `bprate` / `bprate status` | show configured rate, auto-follow, notification |
| `bprate 44100\|48000\|88200\|96000\|176400\|192000\|352800\|384000 [force]` | set the mixer rate (checks the DAC lists it; restarts audioserver) |
| `bprate auto on\|off` | enable/disable follow-the-track daemon |
| `bprate notify on\|off` | status notification (untested) |
| `bprate deepbuffer keep\|trim` | keep or remove `deep_buffer` on USB routes |
| `bpverify` | why the overlay is or is not active (share this when reporting) |
| `bpreport` | **sanitized tester report** (run while playing) → `/sdcard/Download/bitperfect-report.txt` |
| `bpdiag` | environment/policy/AudioFlinger diagnostics → `/data/local/tmp/bpdiag.txt` |
| `bpdump` | full AudioFlinger + policy dumps → `/sdcard/Download/af_full.txt` |
| `bpoffload on\|off\|status` | experiment: disable Qualcomm USB offload at next boot |

Before testing: set **media volume to maximum**, disable AudioFX/EQ/normalisation/crossfade, and read `docs/TESTING.md`.

If the installer says it found nothing to rewrite, it installs in *diagnostic mode* (system untouched); run `bpdiag`.
