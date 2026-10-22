# FAQ and glossary

**Is this bit-perfect?** Not proven. It aims to make Android's mixer match the track's rate with 0 dB gain and no effects. Bit-exactness for DRM streams cannot be proven on-device.

**Why does Android resample at all?** One output thread = one rate. Everything on it is mixed at that rate.

**Does it work with any DAC / phone?** Only tested on one OnePlus 7 / LineageOS 23.2 / one DAC. The module acts only if the audio policy has the expected layout, otherwise it installs in diagnostic mode.

**Spotify?** Not tested yet. Please test and report.

**Why a short dropout when the rate changes?** The audio server must restart to load a new rate.

**Why is my volume "−21 dB"?** Android applied digital attenuation. Put media volume at maximum and adjust on the DAC/amp.

**Does it change my system files?** No. It is a Magisk overlay; remove the module and stock files are back.

**Can I use it with HiFi SRC Bypass / NLSound?** Not recommended; they edit the same files.

**Is a DAC rate display needed?** No. Use `bpstatus`.

## Glossary
- **Mixer / output thread:** AudioFlinger thread that mixes tracks at one rate/format.
- **Mix port / audio policy:** XML description of outputs and routes (`/vendor/etc/audio_policy_configuration.xml`).
- **Overlay:** Magisk's systemless replacement of a file.
- **USB offload:** Qualcomm path where the DSP drives the USB endpoint.
- **PortVol / G db:** digital gain applied to a track in AudioFlinger.
- **Rate-matched:** track rate equals mixer rate (no sample-rate conversion).
