# Security policy

This module runs scripts as **root** at boot and via a daemon, restarts `audioserver`, and mounts replacement config files through Magisk. It makes no network connections.

## Reporting a vulnerability
Please use GitHub's private vulnerability reporting (Security tab → *Report a vulnerability*) rather than a public issue.

## Scope notes
- Scripts read `dumpsys` output and write only inside `/data/adb/usb_dac_bitperfect/`, the module directory and `/data/local/tmp`, plus `/sdcard/Download` copies of diagnostic logs.
- Diagnostic logs may contain package names, pids/uids and device identifiers. Review them before sharing.
- Do not install builds from sources other than this repository's releases; verify the published SHA-256.
