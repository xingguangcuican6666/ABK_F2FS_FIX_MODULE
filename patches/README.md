# Patches

These rollback patches are pre-generated from:

- `android13-5.15-2024-08_r6`
- `android14-6.1-2024-01_r24`
- each supported target monthly tag in the Android 13 / Linux 5.15 and Android 14 / Linux 6.1 windows

Each child module resolves the current monthly tag and applies the matching
stored diff with `git apply --reverse`.

When a specific monthly target has no delta for a child, the corresponding
patch file may be empty and is treated as a valid no-op.
