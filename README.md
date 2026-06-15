# ABK F2FS / Storage Rollback Suite

This ABK external module set rolls back the Android 13 / Linux 5.15 and
Android 14 / Linux 6.1 storage paths for the supported ranges:

- `drivers/ufs`
- `block`
- `fs/f2fs`
- minimal compatibility fixups required after the partial rollback

Rollback source baseline:

- 5.15 target behavior: `android13-5.15-2024-08_r6`
- 6.1 target behavior: `android14-6.1-2024-01_r24`

Supported target window:

- `android13-5.15-2024-09_r8` (`SUBLEVEL=153`)
- ...
- `android13-5.15-2026-03_r12` (`SUBLEVEL=197`)
- `android14-6.1-2024-09_r14` (`SUBLEVEL=93`)
- ...
- `android14-6.1-2026-03_r15` (`SUBLEVEL=162`)

At runtime the module resolves the target monthly tag from:

1. `ABK_BUILD_OS_PATCH_LEVEL`, if available
2. `ABK_BUILD_SUB_LEVEL`
3. `common/Makefile` `SUBLEVEL`, as a fallback

It then selects the matching pre-generated rollback patch set stored in this
repository and applies it with `git apply --reverse`. If the exact monthly
patch no longer matches but a nearby stored patch for the same kernel branch
does, the module will fall back to the nearest applicable patch automatically.

Some 5.15 monthly targets intentionally carry empty patch files for a child
module when that child has no delta at that month; these are treated as no-op
patches.

The module is intended for `after_patch` only. If `ABK_MODULE_CHILD_ID` is not
set, all children are applied in this order:

1. `storage_ufs_rollback`
2. `storage_block_rollback`
3. `storage_f2fs_rollback`
4. `storage_common_fixups`

Optional child kept out of default apply-all:

- `storage_dm_core_crypto_rollback`
  This preserves the low-risk dm core + fs/crypto/fname rollback experiment without changing the suite's default behavior.

## Integration

```bash
export USE_CUSTOM_EXTERNAL_MODULES="true"
export CUSTOM_EXTERNAL_MODULES="https://github.com/xingguangcuican6666/ABK_F2FS_FIX_MODULE.git;after_patch"
```

For a local checkout:

```bash
export USE_CUSTOM_EXTERNAL_MODULES="true"
export CUSTOM_EXTERNAL_MODULES="/run/media/xingguangcuican/Project/testa/ABK_F2FS_FIX_MODULE;after_patch"
```

## Magisk Runtime Policy

The existing Magisk-side dependency is preserved:

- name: `ABK Storage Runtime Policy`
- file: `files/abk_storage_runtime_policy_module.zip`

The ABK metadata exposes the Magisk zip URL for each child entry so frontends
can keep the dependency relationship.
