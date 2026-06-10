# ABK External Module Development

An ABK external module is a normal Git repository. During a build, ABK clones
the repository and runs `setup.sh` at the configured stage.

## Metadata Contract

Every reusable module should provide `module.conf` at the repository root. ABK
uses it before adding a custom module, and `setup.sh` may source it at runtime.
Keep the file shell-compatible and use plain `KEY="VALUE"` assignments.

| Field | Required | Meaning |
| --- | --- | --- |
| `ABK_MODULE_NAME` | Yes | Display name shown in ABK |
| `ABK_MODULE_ID` | Recommended | Stable id for metadata and future control APIs |
| `ABK_MODULE_VERSION` | Recommended | Display version |
| `ABK_MODULE_DESCRIPTION` | Recommended | Short description |
| `ABK_MODULE_REPO_URL` | Recommended | Canonical repository URL |
| `ABK_MODULE_SUPPORTED_STAGES` | Recommended | Comma-separated stages accepted by this module |
| `ABK_MODULE_DEFAULT_STAGE` | Recommended | Fallback stage |
| `ABK_MODULE_RECOMMENDED_STAGES` | Recommended | Comma-separated stages marked as recommended |

ABK currently supports `after_patch` and `before_build`. The app rejects
single-module additions when `module.conf` is missing or invalid, then asks the
user to choose one or more supported stages. Central module repositories should
mirror the same stage data in their catalog JSON.

## Input Format

```text
repo_url;stage|repo_url;stage
```

Example:

```text
https://github.com/your-name/net-patch.git;after_patch|https://github.com/your-name/final-config.git;before_build
```

SC5 tagged format:

```text
module:https://github.com/your-name/net-patch.git;after_patch|set:https://github.com/your-name/module-set.git#feat_guard;before_build
```

Rules:

- `repo_url` supports `https://`, `http://`, `git://`, `ssh://`, and `git@`.
- `stage` supports `after_patch` and `before_build`.
- Every module repository must provide `setup.sh` at the repository root.
- ABK runs the entry point with `bash setup.sh`.

For `set:` items, ABK exports:

- `ABK_MODULE_ENTRY_KIND=module_set_child`
- `ABK_MODULE_GROUP_REPO_URL=<group repo url>`
- `ABK_MODULE_CHILD_ID=<child id>`

## Stage Selection

### after_patch

Use this stage for source integration:

- Apply `git apply` patches.
- Copy drivers, Kconfig files, Makefiles, or headers.
- Add compatibility fixes after ABK built-in patches.

At this point the kernel source tree exists and ABK built-in patches have mostly
finished, but final kernel name and build-time settings may not be written yet.

### before_build

Use this stage for final configuration:

- Edit `$DEFCONFIG`.
- Read `KBUILD_BUILD_TIMESTAMP` or `KBUILD_BUILD_VERSION`.
- Validate the source tree and configuration immediately before compilation.

## Environment Variables

| Variable | Meaning |
| --- | --- |
| `GITHUB_WORKSPACE` | GitHub Actions workspace and ABK repository root |
| `CONFIG` | Build tuple such as `android15-6.6-118` |
| `KERNEL_ROOT` | Kernel source directory |
| `DEFCONFIG` | GKI defconfig path |
| `ZZH_PATCHES` | ABK repository root |
| `SUSFS4KSU` | Expected SUSFS repository path |
| `KERNEL_PATCHES` | `WildKernels/kernel_patches` clone path |
| `SUKISU_PATCHES` | `ShirkNeko/SukiSU_patch` clone path |
| `ANYKERNEL3` | AnyKernel3 clone path |
| `ACTION_BUILD` | Action-Build clone path |
| `CUSTOM_EXTERNAL_MODULES_MANIFEST` | Parsed custom-module manifest TSV file |
| `CUSTOM_EXTERNAL_MODULE_STAGE` | Current stage |
| `REPO` | Android `repo` tool path |
| `REMOTE_BRANCH` | Queried `kernel/common` target branch |
| `ACTUAL_SUBLEVEL` | Actual sublevel read from the kernel `Makefile` |
| `BRANCH` | KernelSU setup branch argument |
| `KSU_LATEST_COMMIT_DATE` | Latest KernelSU commit date |
| `SUSFS_LATEST_COMMIT_DATE` | Latest SUSFS commit date, or `disabled`/localized value when disabled |
| `AVBTOOL` / `MKBOOTIMG` / `UNPACK_BOOTIMG` / `BOOT_SIGN_KEY_PATH` | Packaging and signing tools |
| `CCACHE_DIR` | ccache directory |

Conditional variables:

- `KSU_VERSION`: set for KernelSU Official builds.
- `KBUILD_BUILD_TIMESTAMP` and `KBUILD_BUILD_VERSION`: guaranteed only in
  `before_build`.
- Build parameters exported to every stage:
  `ABK_BUILD_ANDROID_VERSION`, `ABK_BUILD_KERNEL_VERSION`,
  `ABK_BUILD_SUB_LEVEL`, `ABK_BUILD_OS_PATCH_LEVEL`, `ABK_BUILD_REVISION`,
  `ABK_BUILD_KSU_VARIANT`, `ABK_BUILD_KSU_BRANCH`, `ABK_BUILD_VERSION`,
  `ABK_BUILD_TIME`, `ABK_BUILD_VIRTUALIZATION_SUPPORT`, and
  `ABK_BUILD_ZRAM_EXTRA_ALGOS`.
- Feature flags exported as `true` or `false`:
  `ABK_FEATURE_USE_ZRAM`, `ABK_FEATURE_USE_BBG`, `ABK_FEATURE_USE_DDK`,
  `ABK_FEATURE_USE_NTSYNC`, `ABK_FEATURE_USE_NETWORKING`,
  `ABK_FEATURE_USE_KPM`, `ABK_FEATURE_USE_REKERNEL`,
  `ABK_FEATURE_ENABLE_SUSFS`, `ABK_FEATURE_SUPP_OP`, and
  `ABK_FEATURE_ZRAM_FULL_ALGO`.
- Standard GitHub Actions variables such as `GITHUB_REPOSITORY`, `GITHUB_REF`,
  `GITHUB_SHA`, `GITHUB_RUN_ID`, `RUNNER_OS`, `RUNNER_TEMP`, `HOME`, and `PATH`
  are also available.

## Helper Functions

`setup.sh` loads `scripts/libabk.sh`.

| Function | Purpose |
| --- | --- |
| `abk_log "msg"` | Print a normal log line |
| `abk_warn "msg"` | Print a warning |
| `abk_die "msg"` | Print an error and exit |
| `abk_require_env VAR...` | Require environment variables |
| `abk_common_dir` | Print `$KERNEL_ROOT/common` |
| `abk_kernel_version` | Print `major.minor.sublevel` from `common/Makefile` |
| `abk_stage_is after_patch` | Test the current stage |
| `abk_enable_config CONFIG_FOO` | Idempotently set a defconfig symbol to `y` |
| `abk_module_config CONFIG_FOO` | Idempotently set a defconfig symbol to `m` |
| `abk_disable_config CONFIG_FOO` | Idempotently disable a defconfig symbol |
| `abk_append_line_once file line` | Append one line only if missing |
| `abk_apply_patch file.patch [target_dir]` | Idempotently apply one patch |
| `abk_apply_patch_dir patches/dir [target_dir]` | Apply all `*.patch` files in lexical order |
| `abk_copy_into_kernel source relative_target` | Copy a file or directory under `$KERNEL_ROOT` |

## Common Patterns

Apply patches by kernel version:

```bash
kernel_version="$(abk_kernel_version)"
case "$kernel_version" in
  5.10.*)
    abk_apply_patch_dir "$MODULE_DIR/patches/5.10"
    ;;
  5.15.*)
    abk_apply_patch_dir "$MODULE_DIR/patches/5.15"
    ;;
  6.1.*|6.6.*|6.12.*)
    abk_apply_patch_dir "$MODULE_DIR/patches/6.x"
    ;;
  *)
    abk_die "unsupported kernel version: $kernel_version"
    ;;
esac
```

Edit defconfig only in `before_build`:

```bash
if abk_stage_is before_build; then
  abk_enable_config CONFIG_EXAMPLE_FEATURE
fi
```

Copy source files:

```bash
if abk_stage_is after_patch; then
  abk_copy_into_kernel "$MODULE_DIR/files/example_driver" "common/drivers/example_driver"
fi
```

Use semantic source edits when a raw patch would be too brittle:

```bash
source_file="$(abk_common_dir)/fs/f2fs/super.c"
abk_require_file "$source_file"
# Validate a stable function-level anchor, then rewrite only the target lines.
```

## Pre-commit Checks

At minimum, run:

```bash
bash -n setup.sh scripts/libabk.sh
```

If your module includes patches, check the ABK build log and confirm:

- Patches apply cleanly.
- Re-running the module does not duplicate changes.
- Unsupported kernel versions fail clearly.
- Kconfig symbols exist before adding strict defconfig expectations.

## Compatibility Advice

- Do not assume one fixed kernel sublevel. Read `CONFIG` or use
  `abk_kernel_version`.
- Prefer function-anchored semantic edits over raw patches when you only need
  to rewrite a few stable defaults and upstream context around them drifts.
- Handle Android 12/13 5.x and Android 14+ Bazel/Kleaf differences explicitly.
- Do not hardcode paths such as `$GITHUB_WORKSPACE/android15-6.6-118`; use
  `$KERNEL_ROOT`.
- Pin external dependencies to tags or commits when reproducibility matters.
