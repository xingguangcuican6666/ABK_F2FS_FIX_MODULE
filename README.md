# ABK F2FS / Storage Rollback Suite

This ABK external module set rolls back the Android 14 / Linux 6.1 storage
paths for the supported `93..162` range:

- `drivers/ufs`
- `block`
- `fs/f2fs`
- minimal compatibility fixups required after the partial rollback

Rollback source baseline:

- target behavior: `android14-6.1-2024-01_r24`

Supported target window:

- `android14-6.1-2024-09_r14` (`SUBLEVEL=93`)
- ...
- `android14-6.1-2026-03_r15` (`SUBLEVEL=162`)

At runtime the module resolves the target monthly tag from:

1. `ABK_BUILD_OS_PATCH_LEVEL`, if available
2. `ABK_BUILD_SUB_LEVEL`
3. `common/Makefile` `SUBLEVEL`, as a fallback

It then selects the matching pre-generated rollback patch set stored in this
repository and applies it with `git apply --reverse`.

The module is intended for `after_patch` only. If `ABK_MODULE_CHILD_ID` is not
set, all children are applied in this order:

1. `storage_ufs_rollback`
2. `storage_block_rollback`
3. `storage_f2fs_rollback`
4. `storage_common_fixups`

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
