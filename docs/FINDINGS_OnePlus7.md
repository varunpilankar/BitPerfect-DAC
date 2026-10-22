# Findings from the reference device

Reference setup (reported by the first tester): OnePlus 7 (`guacamoleb`, Snapdragon 855), LineageOS 23.2 nightly (2026-09-20), Android 16, Magisk with other modules, CrinEar Protocol Micro USB DAC, Apple Music 24-bit/96 kHz track. Data came from `bpdiag`/`bpdump` text output; personal identifiers were removed from the excerpts below.

## F1 — USB audio is not a separate port; it uses the primary HAL's mix ports
`audio_policy_configuration.xml` has no static USB output mix port apart from `usb_accessory output` (host-mode accessory) and the sink `usb_surround_sound`. `USB Device Out` / `USB Headset Out` are device ports attached to `primary output`, `raw`, `deep_buffer`, `direct_pcm`, `compressed_offload`, `voip_rx`, `mmap_no_irq_out` and `hifi_playback`. → rewriting static USB rates (module v0.1) cannot work here.

## F2 — Stock behaviour: music on a 384 kHz / 32-bit thread
With nothing modified, an output thread routed to `AUDIO_DEVICE_OUT_USB_HEADSET` ran at **384000 Hz, `PCM_32_BIT`**, flags `AUDIO_OUTPUT_FLAG_NONE`, and held the active media track. The policy dump showed `hifi_playback` with `[dynamic format][dynamic channels][dynamic rates]` plus a DAC-derived profile listing 44.1/48/96/192/384 kHz. A second USB thread (`primary output`) sat at 48 kHz / 16-bit. FIFO underrun counters on the 384 kHz thread were in the thousands.

## F3 — Pinning `hifi_playback` works at the policy level (v0.5)
After installing v0.5 a `hifi_playback` thread appeared at **44100 Hz / 32-bit**. But the active media track was then on the `deep_buffer` output at **48 kHz / 16-bit** (flags `DEEP_BUFFER`), i.e. worse than before. → v0.6 removes `deep_buffer` from the USB routes.

## F4 — Real Android 16 track-table layout
```
Type  Id Active Client(pid/uid) Session Port Id S Flags Format Chn mask SRate ST Usg CT G db L dB R dB VS dB PortVol dB PortMuted ...
      58 yes    4990/  10198     233      40 A 0x000 00000005 00000003 96000  3  1  0 -21   0    0    0         -21      false ...
```
The track was **96000 Hz, `PCM_FLOAT`, gain −21 dB** while the mixer thread was 384000 Hz. Header and row token counts differ (see ARCHITECTURE.md).

## F5 — Volume is applied digitally in AudioFlinger
`PortVol dB = -21` with `L/R/VS = 0`. Media volume was below maximum, so AudioFlinger attenuated by 21 dB. Not bit-exact. (Whether a USB hardware/absolute-volume path exists was not investigated; the dump listed a `setDeviceAbsoluteVolumeEnabled` call counter, meaning the framework path exists, but its effect on USB was not examined.)

## F6 — Effects on the music session
Attached to the same session: Equalizer, Dynamic Bass Boost, Virtualizer, Insert Preset Reverb (all *Disabled*; attached by LineageOS AudioFX) and **Volume listener for Music (*Enabled; Active*)**, a Qualcomm effect. The module's `bpstatus` prints enabled effects.

## F7 — USB offload
`vendor.audio.feature.usb_offload.enable=true`. During playback `/proc/asound/card0/pcm0p/sub0/hw_params` read `closed` and `stream0` showed `Status: Stop`; the host ALSA driver was not carrying the stream. The DAC advertised 44100, 48000, 96000, 192000 and 384000 Hz (no 88.2 / 176.4 kHz).

## F8 — Overlay absent in the v0.8 session
In the v0.8 dump `Config source` was `/vendor/etc/audio_policy_configuration.xml`, `hifi_playback` was still dynamic, and `deep_buffer` still listed both USB device ports. So neither policy edit was live. Cause unknown (see HANDOVER.md §5.1).

## What these findings do **not** show
- Whether a pinned, rate-matched, unity-gain, effect-free stream reaches the DAC unchanged (never captured).
- Whether Spotify behaves like Apple Music (never captured).
- Whether the DAC receives the mixer's rate under offload.
