# ABK F2FS / Storage Fix Suite

ABK module-set repository for the post-FIDO precompiled storage patch modules
used in the local `.local-build/env.sh` flow.

## Included children

- `ABK F2FS Perf Fix`
- `ABK F2FS LowDepth Fix`
- `ABK UFS PM Fix`
- `ABK dm-default-key Fix`

`ABK F2FS LowDepth Fix` uses a scripted semantic edit of
`fs/f2fs/super.c::default_options()` rather than a raw patch so it survives
small Android common `6.1.x` source drift and earlier `super.c` edits.

`ABK UFS PM Fix` uses a scripted semantic edit of
`drivers/ufs/core/ufshcd.c` so it can handle both the older unconditional PM
defaults and the newer guarded `rpm_lvl` / `spm_lvl` initialization found in
later Android common `6.1.x` tags.

The app reads the child list from `module.conf` and expands user selections
into flat `set:https://github.com/xingguangcuican6666/ABK_F2FS_FIX_MODULE#child_id;stage`
workflow inputs.

## Runtime Magisk dependency

All children require the same ordinary Magisk module:

- `ABK Storage Runtime Policy`
- Download URL:
  `https://raw.githubusercontent.com/xingguangcuican6666/ABK_F2FS_FIX_MODULE/main/files/abk_storage_runtime_policy_module.zip`

When users flash a boot image or AnyKernel3 bundle produced from a build that
used one of these children, ABK installs that Magisk module first and only then
continues with flashing.

## Repository layout

```text
.
|-- module.conf
|-- setup.sh
|-- scripts/
|   |-- libabk.sh
|   `-- abk_storage_fix_suite.sh
|-- patches/
|   |-- abk_f2fs_perf_fix/
|   `-- abk_dm_default_key_fix/
`-- files/
    `-- abk_storage_runtime_policy_module.zip
```

## Behavior

`setup.sh` supports two modes:

- if `ABK_MODULE_CHILD_ID` is set, only that child patchset is applied
- if it is empty, all four child patchsets are applied in order

That keeps the repository usable both as an app-driven module set and as a
manual “apply all storage fixes” module.

Patch-driven children continue to read from `patches/`. The lowdepth child is
implemented directly in `scripts/abk_storage_fix_suite.sh`
so it can validate and rewrite only the two intended defaults. The UFS PM child
uses the same scripted approach for `ufshcd.c`.
