# Patches

These rollback patches are pre-generated from:

- `android14-6.1-2024-01_r24`
- each supported target monthly tag in the Android 14 / Linux 6.1 `93..162` window

Each child module resolves the current monthly tag and applies the matching
stored diff with `git apply --reverse`.
