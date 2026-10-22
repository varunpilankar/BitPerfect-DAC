# Security policy

This module runs scripts as **root** at boot and via a daemon, restarts `audioserver`, and mounts replacement config files through Magisk. It makes no network connections.

## Supported versions

| Version | Supported | Notes |
| --- | --- | --- |
| `0.9.x` | Yes (experimental) | Current pre-release series on `main` |
| `< 0.9.0` | No | Early iterations superseded by v0.9.x safety and parser fixes |

## Reporting a vulnerability
Please use GitHub's private vulnerability reporting ([Security tab → *Report a vulnerability*](https://github.com/varunpilankar/BitPerfect-DAC/security/advisories/new)) rather than a public issue.

## Scope notes
- Scripts read `dumpsys` output and write only inside `/data/adb/usb_dac_bitperfect/`, the module directory and `/data/local/tmp`, plus `/sdcard/Download` copies of diagnostic logs.
- Diagnostic logs (`bpdump`, `bpdiag`) may contain package names, pids/uids and device identifiers. Use `bpreport` for a sanitized report, and always review logs before sharing publicly.
- Do not install builds from sources other than this repository's [GitHub Releases](https://github.com/varunpilankar/BitPerfect-DAC/releases); always verify the published SHA-256 checksum (`sha256sum -c BitPerfect-DAC-<version>.zip.sha256`).
