# Install, update, uninstall, recovery

> Experimental software that edits audio configuration through a root module. Know how to recover before you flash.

## Requirements
- Rooted device with Magisk. Developed on Android 16 / LineageOS 23.2 (Qualcomm). Other setups are untested.
- External USB DAC.
- A way to recover: Magisk safe mode, a custom recovery or `adb shell`/terminal root access.

## Before you flash
1. Optional but valuable: capture a **baseline** while a track plays (see the baseline command in [TESTER_GUIDE.md](TESTER_GUIDE.md)).
2. Disable other modules that edit audio policy/effects (HiFi SRC Bypass, NLSound, similar). Reboot.
3. Back up your data.

## Install
1. Download `BitPerfect-DAC-<version>.zip` and its `.sha256` from Releases. Check: `sha256sum -c BitPerfect-DAC-<version>.zip.sha256`.
2. Magisk → Modules → **Install from storage** → pick the ZIP.
3. **Read the installer output.** One line per audio-policy file says *patched* or *skipped* and why. The same text is saved to `/sdcard/Download/bitperfect_install.log`.
   - `patched: … -> 44100 Hz` – an overlay was created.
   - `DIAGNOSTIC mode (system untouched)` – nothing matched this ROM; run `su -c bpdiag` and share it.
   - `Aborted: … Remove the module, reboot, install again` – see Update.
4. **Reboot.** The overlay only takes effect after a reboot.
5. Plug in the DAC, play a track, then `su -c bpverify` and `su -c bpstatus`.

## Update
Install the new ZIP over the old one and reboot. Since v0.8 the installer reuses saved pristine copies of the audio policy so it never mistakes its own overlay for the original. If it aborts with "already patched, no pristine copy found": remove the module, reboot, install again.

## Uninstall
- Magisk app → Modules → remove → reboot, **or**
- root shell: `touch /data/adb/modules/usb_dac_bitperfect/remove` and reboot.

After removal `/vendor/etc/audio_policy_configuration.xml` is the untouched stock file (the module never edits it). State in `/data/adb/usb_dac_bitperfect/` is removed by the uninstall script.

## Recovery
| Situation | Action |
| --- | --- |
| No audio after install | Reboot twice: the boot guard disables the overlay after two boots where audio failed to start |
| Bootloop / cannot reach Magisk | Boot Magisk **safe mode** (varies by device), or from recovery delete `/data/adb/modules/usb_dac_bitperfect` |
| Module shows "DISABLED by boot guard" | Audio failed twice. Reinstall after reading `bpverify`/`boot.log`, or leave it removed |
| Audio too slow / low-pitched | `su -c 'bprate 48000'` or remove the module |

Stop the daemon without removing: `su -c 'bprate auto off'`.
