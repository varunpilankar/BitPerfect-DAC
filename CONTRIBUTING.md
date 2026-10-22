# Contributing

Thanks for helping. This project is experimental and evidence-driven.

## Ground rules
- **Evidence over claims.** A change that alters audio behaviour needs before/after output from `bpstatus`, `bpverify` and, where relevant, `bpdump` (sanitized).
- **No unverified statements in docs.** Mark unknowns as unknown.
- **Reversible and safe.** Nothing may write to `/vendor` or `/system` directly; use the Magisk overlay. Keep the boot guard and `patch_ok` sanity checks.
- **Licence.** Contributions are licensed under GPL-3.0 (see `LICENSE`). Do not paste code from incompatible licences; describe prior art in `docs/DECISIONS.md` instead.

## Development
```sh
sh tests/run.sh        # must pass
sh scripts/build.sh    # builds dist/ZIP
```
- Shell must run under Android `mksh`/toybox and Magisk busybox `awk`: POSIX only, no arrays, no `[[ ]]`, no process substitution.
- Parsing of `dumpsys` output lives in `module/common.sh`. Add a fixture under `tests/fixtures/` and an assertion in `tests/run.sh` for every new layout.
- Keep `docs/` in sync (COMPATIBILITY, TROUBLESHOOTING, CHANGELOG).

## Pull request checklist
- [ ] Tests pass; new fixture added if parsing changed
- [ ] Device, ROM, Android version, root solution, DAC, app tested (or "not tested on device")
- [ ] Install, update-over-previous, reboot, uninstall checked
- [ ] Docs and CHANGELOG updated
- [ ] No personal data in logs
