# ABK F2FS / Storage Rollback Suite

This ABK external module set rolls back the Android 14 / Linux 6.1 storage
paths that were validated locally for the 6.1.118 build:

- `drivers/ufs`
- `block`
- `fs/f2fs`
- minimal compatibility fixups required after the partial rollback

Rollback source range:

- target behavior: `android14-6.1-2024-01_r24`
- current build base: `android14-6.1-2025-01_r29`

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
