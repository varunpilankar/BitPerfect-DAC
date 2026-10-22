# Changelog

All notable changes. Versions are module versions (`module/module.prop`). Nothing here is a validated release.

## 0.9.1
- `bpreport`: sanitized tester report; `sanitize_report` helper (test added).
- Early-adopter documentation set: README rewrite, INSTALL, TESTER_GUIDE, FAQ; CI and pre-release workflows.

## 0.9.0
- Track-table parser rewritten against a real Android 16 dump (anchor on the `yes`/`no` Active token; handles blank `Type` and split `pid/ uid`).
- `bpstatus` reports gain (`G db`), enabled effects, source bit depth and kbps; flags `RESAMPLED`, `VOLUME`, float source.
- New `bpverify` (module/overlay/mount/policy diagnosis) and installer log.
- Offline test-suite (`tests/run.sh`, 28 checks) and fixtures.

## 0.8.0
- Installer no longer treats its own overlay as the pristine file; reuses saved pristine copies or a Magisk mirror; aborts instead of shipping an empty overlay on update.
- Boot guard disables only after 2 consecutive failed boots.
- `bpdump`; track table located via the "Tracks of which" line.

## 0.7.0
- Single `dumpsys` per poll, faster follow loop, wait-for-audioserver instead of fixed sleep, timing log.
- Bit depth and kbps in status; optional notification (untested).

## 0.6.0
- Remove `deep_buffer` from USB routes (`bprate deepbuffer keep|trim`); track tables in `bpcheck`/`bpdiag`.

## 0.5.0
- Pin the dynamic `hifi_playback` mix port to one static profile (first change observed to take effect on the reference device).
- `bpoffload`, USB thread info.

## 0.4.0 / 0.3.0 / 0.2.0 / 0.1.0
- Diagnostic installer and `bpdiag` (0.3), parser attempts (0.2, 0.4), auto-follow daemon (0.2), static USB mix-port rate rewrite with `bpcheck`/`bprate` (0.1).
